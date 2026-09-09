import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/create_organization_screen.dart';
import '../screens/join_organization_screen.dart';
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
          const SizedBox(height: 14),

          // Organization & Workspace Controls
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.corporate_fare_rounded, size: 16, color: AppColors.cyan),
                        const SizedBox(width: 8),
                        Text(
                          service.currentOrg?.name ?? 'Organization',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service.currentOrg?.domain ?? user.companyDomain,
                        style: const TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => JoinOrganizationScreen(service: service)),
                          );
                        },
                        icon: const Icon(Icons.group_add_rounded, size: 14, color: AppColors.cyan),
                        label: const Text('Join / Switch Org', style: TextStyle(fontSize: 11, color: AppColors.cyan, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppColors.borderHover),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CreateOrganizationScreen(service: service)),
                          );
                        },
                        icon: const Icon(Icons.add_business_rounded, size: 14, color: AppColors.primaryLight),
                        label: const Text('Create Org', style: TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppColors.borderHover),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Identity Key Recovery Protocol Card (Solves Key-Loss Risk)
          _buildIdentityRecoveryCard(context),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Identity Guardian & Key Recovery Protocol UI
  // ---------------------------------------------------------------------------

  Widget _buildIdentityRecoveryCard(BuildContext context) {
    final recovery = service.identityRecovery;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.key_rounded, size: 16, color: AppColors.cyan),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Identity Guardian & Key Recovery',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${recovery.threshold}-of-${recovery.guardians.length} GUARDIANS',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.emerald),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Protects against permanent lockout if your device or Ed25519 key is lost. Guardians can rotate the controller key without altering your Identity PDA or losing assets.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
          ),
          const SizedBox(height: 12),

          // Guardian List
          ...recovery.guardians.map((g) {
            final isApproved = recovery.approvedGuardians.contains(g);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isApproved ? Icons.verified_rounded : Icons.person_outline_rounded,
                        size: 14,
                        color: isApproved ? AppColors.emerald : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(g, style: const TextStyle(fontSize: 11, color: AppColors.textMain, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: (isApproved ? AppColors.emerald : AppColors.textDim).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isApproved ? 'APPROVED' : 'STANDBY',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: isApproved ? AppColors.emerald : AppColors.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // Recovery Action Buttons
          if (recovery.isInProgress) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.amber),
                      const SizedBox(width: 6),
                      Text(
                        'Key Rotation Proposal Active (${recovery.approvalCount}/${recovery.threshold} Approvals)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proposed Controller: ${recovery.activeRecoveryNewController}',
                    style: AppTheme.mono(fontSize: 10, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (recovery.approvalCount < recovery.threshold)
              ElevatedButton.icon(
                onPressed: () {
                  final unapproved = recovery.guardians.firstWhere(
                    (g) => !recovery.approvedGuardians.contains(g),
                    orElse: () => recovery.guardians.first,
                  );
                  service.approveIdentityRecovery(unapproved);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Guardian "$unapproved" endorsed key rotation!'), backgroundColor: AppColors.emerald),
                  );
                },
                icon: const Icon(Icons.thumb_up_alt_rounded, size: 14),
                label: const Text('Guardian 2 Endorsement (2nd Signature)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  service.executeIdentityRecovery();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Device key rotated! Identity PDA and assets preserved.'), backgroundColor: AppColors.emerald),
                  );
                },
                icon: const Icon(Icons.autorenew_rounded, size: 14),
                label: const Text('Execute Controller Key Rotation (Solana Devnet)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size.fromHeight(38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ] else
            OutlinedButton.icon(
              onPressed: () {
                service.initiateIdentityRecovery(newDeviceKey: 'RotatedDeviceKey${DateTime.now().millisecondsSinceEpoch % 10000}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Initiated key recovery flow! Proposing new controller key.'), backgroundColor: AppColors.cyan),
                );
              },
              icon: const Icon(Icons.build_circle_outlined, size: 14, color: AppColors.cyan),
              label: const Text('Test Lost Key Recovery & Rotation Flow', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.cyan)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.4)),
                minimumSize: const Size.fromHeight(38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }
}
