import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';
import 'receive_modal.dart';

class IdentityPassView extends StatelessWidget {
  final SolanaService service;

  const IdentityPassView({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final user = service.currentUser;
    if (user == null) return const SizedBox.shrink();

    final permissions = service.currentPermissions;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Holographic Identity Pass Card (Phantom style)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1E1B4B), // Deep indigo
                  Color(0xFF0F172A), // Slate black
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Org Name + Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user.companyDomain} Identity',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: AppColors.emerald),
                          SizedBox(width: 4),
                          Text(
                            'VERIFIED',
                            style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name & Role
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.role,
                        style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mask: 0x${user.permissionsMask.toRadixString(16).toUpperCase()}',
                      style: AppTheme.mono(fontSize: 11, color: AppColors.textDim),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Identity PDA Row
                const Text('Self-Sovereign Identity PDA', style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        user.identityPda,
                        style: AppTheme.mono(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: user.identityPda));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Identity PDA copied'),
                            duration: Duration(seconds: 1),
                            backgroundColor: AppColors.bgCard,
                          ),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.cyan),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Controller Public Key Row
                const Text('Controller Public Key (Signer)', style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        user.publicKey,
                        style: AppTheme.mono(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: user.publicKey));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Controller Public Key copied'),
                            duration: Duration(seconds: 1),
                            backgroundColor: AppColors.bgCard,
                          ),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.cyan),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions: QR Code / Sign Out
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showReceiveModal(context, service),
                  icon: const Icon(Icons.qr_code_rounded, size: 16, color: AppColors.cyan),
                  label: const Text('Show ID Pass', style: TextStyle(fontSize: 12, color: AppColors.cyan)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.borderHover),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => service.signOut(),
                  icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.rose),
                  label: const Text('Sign Out', style: TextStyle(fontSize: 12, color: AppColors.rose)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.rose.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // RBAC Permissions Breakdown
          const Text(
            'Enforced On-Chain Permissions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          const SizedBox(height: 6),
          const Text(
            'Permissions are verified trustlessly by the Solana program on Devnet via 64-bit bitmasks.',
            style: TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: permissions.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final perm = permissions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: perm.isGranted
                              ? AppColors.emerald.withValues(alpha: 0.15)
                              : AppColors.rose.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          perm.isGranted ? Icons.check_rounded : Icons.close_rounded,
                          size: 16,
                          color: perm.isGranted ? AppColors.emerald : AppColors.rose,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              perm.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: perm.isGranted ? AppColors.textMain : AppColors.textDim,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              perm.description,
                              style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '0x${perm.mask.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                        style: AppTheme.mono(
                          fontSize: 11,
                          color: perm.isGranted ? AppColors.primaryLight : AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
