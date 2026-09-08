import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../screens/join_organization_screen.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';
import 'assign_role_modal.dart';
import 'create_asset_modal.dart';
import 'invite_member_modal.dart';

class AdminHubView extends StatelessWidget {
  final SolanaService service;

  const AdminHubView({super.key, required this.service});

  void _showTopUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Top Up Gas Treasury', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
        content: const Text(
          'Fund the organization treasury with 5.0 SOL to guarantee 100% sponsored, gas-free transactions for all active members.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.topUpTreasury(5.0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Treasury funded with ◎ 5.0 SOL!'),
                  backgroundColor: AppColors.emerald,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Fund ◎ 5.0 SOL', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmRevokeAsset(BuildContext context, DigitalAsset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 20),
            SizedBox(width: 8),
            Text('Revoke Asset PDA?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          ],
        ),
        content: Text(
          'Are you sure you want to freeze and revoke "${asset.name}"? This action is recorded immutably on Solana Devnet and prevents future transfers.',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.revokeDigitalAsset(asset.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Revoke Asset', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final org = service.currentOrg;
    final user = service.currentUser;
    final members = service.currentOrgMembers;
    final assets = service.assets;

    if (org == null) {
      return const Center(child: Text('No organization selected', style: TextStyle(color: AppColors.textDim)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Organization Authority Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.bgCard,
                AppColors.primary.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: org.brandColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: org.brandColor),
                    ),
                    child: Center(
                      child: Text(
                        org.name.isNotEmpty ? org.name[0] : 'O',
                        style: TextStyle(color: org.brandColor, fontSize: 18, fontWeight: FontWeight.w800),
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
                            Flexible(
                              child: Text(
                                org.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('ADMIN CONSOLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.purple)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(org.domain, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => JoinOrganizationScreen(service: service)),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.cyan),
                          SizedBox(width: 4),
                          Text('Switch', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.cyan)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Authority PDA Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Authority PDA:', style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                  Row(
                    children: [
                      Text(org.shortAuthority, style: AppTheme.mono(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: org.authorityPda));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Authority PDA copied'), duration: Duration(seconds: 1)),
                          );
                        },
                        child: const Icon(Icons.copy_rounded, size: 13, color: AppColors.cyan),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 18, color: AppColors.border),

              // Treasury & Sponsorship Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sponsorship Treasury', style: TextStyle(fontSize: 10, color: AppColors.textDim)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('◎ ${org.treasuryBalance.toStringAsFixed(1)} SOL',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.emerald)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                            child: const Text('100% SPONSORED', style: TextStyle(fontSize: 8, color: AppColors.emerald, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showTopUpDialog(context),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.emerald),
                    label: const Text('Top Up', style: TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Actions Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => showInviteMemberModal(context, service),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Invite User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => showCreateAssetModal(context, service),
                icon: const Icon(Icons.add_box_rounded, size: 16),
                label: const Text('Create Asset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Role Testing Quick Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, size: 14, color: AppColors.purple),
                  const SizedBox(width: 6),
                  Text('Active Role: ${user?.role ?? "Admin"}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              InkWell(
                onTap: () => service.toggleCurrentUserRole(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Toggle Role', style: TextStyle(fontSize: 10, color: AppColors.purple, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Member Roster Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Organization Members (${members.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain),
            ),
            InkWell(
              onTap: () => showInviteMemberModal(context, service),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, size: 16, color: AppColors.primaryLight),
                  SizedBox(width: 2),
                  Text('New Member', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Member Cards List
        ...members.map((member) {
          final isSelf = member.email == user?.email;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: member.avatarColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: member.avatarColor),
                  ),
                  child: Center(
                    child: Text(
                      member.name.isNotEmpty ? member.name[0] : 'U',
                      style: TextStyle(color: member.avatarColor, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text('YOU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.primaryLight)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(member.email, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: member.role.toLowerCase().contains('admin')
                                  ? AppColors.rose.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              member.role,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: member.role.toLowerCase().contains('admin') ? AppColors.rose : AppColors.primaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('Mask: 0x${member.permissionsMask.toRadixString(16).toUpperCase()}',
                              style: AppTheme.mono(fontSize: 10, color: AppColors.textDim)),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => showAssignRoleModal(context, service, member),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: const BorderSide(color: AppColors.borderHover),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(60, 30),
                  ),
                  child: const Text('Edit Role', style: TextStyle(fontSize: 11, color: AppColors.textMain, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Organization Digital Assets Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Organization Assets (${assets.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain),
            ),
            InkWell(
              onTap: () => showCreateAssetModal(context, service),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, size: 16, color: AppColors.cyan),
                  SizedBox(width: 2),
                  Text('Mint Asset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.cyan)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Assets List
        ...assets.map((asset) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: asset.isRevoked ? AppColors.rose.withValues(alpha: 0.4) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: asset.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(asset.icon, color: asset.accentColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              asset.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: asset.isRevoked ? AppColors.textDim : AppColors.textMain,
                                decoration: asset.isRevoked ? TextDecoration.lineThrough : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: asset.isRevoked ? AppColors.rose.withValues(alpha: 0.2) : AppColors.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              asset.isRevoked ? 'REVOKED' : 'ACTIVE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: asset.isRevoked ? AppColors.rose : AppColors.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Owner: ${asset.ownerLabel}', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                      const SizedBox(height: 1),
                      Text(asset.shortPda, style: AppTheme.mono(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (!asset.isRevoked)
                  IconButton(
                    icon: const Icon(Icons.block_rounded, size: 18, color: AppColors.rose),
                    tooltip: 'Revoke / Freeze Asset',
                    onPressed: () => _confirmRevokeAsset(context, asset),
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),
      ],
    );
  }
}
