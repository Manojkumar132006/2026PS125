import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../screens/join_organization_screen.dart';
import '../services/biometric_service.dart';
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
            Icon(Icons.shield_outlined, color: AppColors.amber, size: 20),
            SizedBox(width: 8),
            Text('PoA Consensus Revocation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Under Proof of Authority (PoA) governance, revoking "${asset.name}" is a protected critical operation requiring 2-of-3 Quorum consensus.',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.fingerprint_rounded, color: AppColors.cyan, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Submitting will create Proposal #2 with your Biometric Hardware Signature.',
                      style: TextStyle(fontSize: 11, color: AppColors.textDim),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.createConsensusProposal(
                title: 'Emergency Revocation: ${asset.name}',
                description: 'Permanent on-chain revocation of Asset PDA ${asset.shortPda} requested under PoA quorum.',
                actionType: 3, // Revoke Resource
                targetAddress: asset.pdaAddress,
                targetLabel: asset.name,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Revocation Proposal created! Awaiting 2nd Guardian approval.'),
                  backgroundColor: AppColors.cyan,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Submit Proposal', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveWithBiometrics(
    BuildContext context,
    ConsensusProposalModel proposal,
    String authorityName,
  ) async {
    try {
      final authenticated = await BiometricService.authenticate(
        reason: 'Touch fingerprint sensor to approve PoA Consensus Proposal #${proposal.proposalId} as $authorityName',
      );

      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric verification cancelled. Fingerprint authentication is required to endorse proposal.'),
              backgroundColor: AppColors.amber,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final success = await service.approveConsensusProposal(
        proposal.proposalId,
        authorityName: authorityName,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Fingerprint verified via Secure Enclave! Proposal #${proposal.proposalId} approved by $authorityName'),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.code == 'NotEnrolled' || e.code == 'PasscodeNotSet'
                ? 'No fingerprint enrolled on device. Please enroll a fingerprint in Android Settings > Security.'
                : 'Biometric error (${e.code}): ${e.message}'),
            backgroundColor: AppColors.rose,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: AppColors.rose,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showCreateProposalModal(BuildContext context) {
    final titleCtrl = TextEditingController(text: 'Revoke Compromised Edge Key #3');
    final descCtrl = TextEditingController(text: 'Suspected key compromise on edge server. Revocation requested via PoA consensus.');
    int selectedAction = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                  const Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: AppColors.cyan, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'New PoA Consensus Proposal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Requires threshold consensus (2-of-3 authorities) with biometric confirmation.',
                    style: TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedAction,
                    dropdownColor: AppColors.bgSecondary,
                    decoration: InputDecoration(
                      labelText: 'Critical Action Type',
                      labelStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.bgSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('Permanent Resource Revocation (revoke_resource)', style: TextStyle(color: AppColors.textMain, fontSize: 12))),
                      DropdownMenuItem(value: 1, child: Text('Assign Master ADMIN Role (0x3F)', style: TextStyle(color: AppColors.textMain, fontSize: 12))),
                      DropdownMenuItem(value: 4, child: Text('Rotate Authority Quorum Keys', style: TextStyle(color: AppColors.textMain, fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedAction = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Proposal Title',
                      labelStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.bgSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Audit Justification',
                      labelStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.bgSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      service.createConsensusProposal(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        actionType: selectedAction,
                        targetAddress: 'pda_res_edge_key_3',
                        targetLabel: 'Edge Server Key #3',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PoA Proposal submitted to Quorum (1/2 Approvals)'),
                          backgroundColor: AppColors.cyan,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fingerprint_rounded, size: 18),
                    label: const Text('Sign with Biometric Key & Propose', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        const SizedBox(height: 18),

        // Proof of Authority (PoA) Consensus Governance Card
        _buildPoAConsensusCard(context),
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

  // ---------------------------------------------------------------------------
  // Proof of Authority (PoA) Consensus Governance UI
  // ---------------------------------------------------------------------------

  Widget _buildPoAConsensusCard(BuildContext context) {
    final quorum = service.quorumConfig;
    final proposals = service.proposals;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: AppColors.cyan.withValues(alpha: 0.2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.shield_rounded, color: AppColors.cyan, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proof of Authority Consensus',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMain),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '2-of-3 Quorum & Biometric Gate',
                            style: TextStyle(fontSize: 10, color: AppColors.textDim),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action button to propose new consensus action
                    ElevatedButton.icon(
                      onPressed: () => _showCreateProposalModal(context),
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text('Propose', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quorum Badges Row wrapped cleanly to prevent overflow on compact screens
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.emerald)),
                          const SizedBox(width: 6),
                          Text(
                            'Active Quorum: ${quorum.threshold}-of-${quorum.totalAuthorities} Authorities',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emerald),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fingerprint_rounded, size: 12, color: AppColors.purple),
                          SizedBox(width: 4),
                          Text(
                            'Hardware Enclave Gated',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.purple),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Threat Mitigation Explanatory Callout
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_rounded, size: 14, color: AppColors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anti-Compromise Guard: Even if an admin key is compromised, destructive actions (e.g. revoking assets, assigning ADMIN) cannot execute without 2-of-3 consensus signatures.',
                          style: TextStyle(fontSize: 10, color: AppColors.textDim, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Proposals List
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consensus Proposals (${proposals.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMain),
                    ),
                    const Text(
                      'On-Chain State: Devnet',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (proposals.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No active consensus proposals', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                    ),
                  )
                else
                  ...proposals.map((proposal) {
                    final isPending = proposal.status == ProposalStatus.pending;
                    final isApproved = proposal.status == ProposalStatus.approved;
                    final isExecuted = proposal.status == ProposalStatus.executed;
                    final isRejected = proposal.status == ProposalStatus.rejected;

                    final progress = (proposal.currentApprovals / proposal.requiredThreshold).clamp(0.0, 1.0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isExecuted
                              ? AppColors.emerald.withValues(alpha: 0.3)
                              : isApproved
                                  ? AppColors.cyan.withValues(alpha: 0.4)
                                  : isRejected
                                      ? AppColors.rose.withValues(alpha: 0.3)
                                      : AppColors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: (proposal.actionType == 3 ? AppColors.rose : AppColors.cyan).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  proposal.actionType == 3 ? Icons.block_rounded : Icons.admin_panel_settings_rounded,
                                  size: 16,
                                  color: proposal.actionType == 3 ? AppColors.rose : AppColors.cyan,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            proposal.title,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isExecuted
                                                ? AppColors.emerald.withValues(alpha: 0.2)
                                                : isApproved
                                                    ? AppColors.cyan.withValues(alpha: 0.2)
                                                    : isRejected
                                                        ? AppColors.rose.withValues(alpha: 0.2)
                                                        : AppColors.amber.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isExecuted
                                                ? 'EXECUTED'
                                                : isApproved
                                                    ? 'CONSENSUS REACHED'
                                                    : isRejected
                                                        ? 'VETOED'
                                                        : 'PENDING (${proposal.currentApprovals}/${proposal.requiredThreshold})',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: isExecuted
                                                  ? AppColors.emerald
                                                  : isApproved
                                                      ? AppColors.cyan
                                                      : isRejected
                                                          ? AppColors.rose
                                                          : AppColors.amber,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      proposal.description,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textDim, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Approval Progress Bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: AppColors.bgCard,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isExecuted
                                          ? AppColors.emerald
                                          : isApproved
                                              ? AppColors.cyan
                                              : AppColors.amber,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${proposal.currentApprovals}/${proposal.requiredThreshold} Approvals',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Endorsed Authorities
                          Row(
                            children: [
                              const Text('Endorsed: ', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              Expanded(
                                child: Text(
                                  proposal.approvedBy.join(', '),
                                  style: const TextStyle(fontSize: 10, color: AppColors.cyan, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Interactive Action Buttons
                          if (isPending) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Next guardian in quorum who hasn't approved
                                      final remaining = quorum.authorityNames.firstWhere(
                                        (name) => !proposal.approvedBy.contains(name),
                                        orElse: () => 'Marcus Vance (Guardian 2)',
                                      );
                                      _approveWithBiometrics(context, proposal, remaining);
                                    },
                                    icon: const Icon(Icons.fingerprint_rounded, size: 16),
                                    label: const Text('Approve with Biometric Touch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.cyan,
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => service.rejectConsensusProposal(proposal.proposalId, authorityName: 'Guardian 2'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.rose.withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Veto', style: TextStyle(fontSize: 11, color: AppColors.rose, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ] else if (isApproved) ...[
                            ElevatedButton.icon(
                              onPressed: () => service.executeConsensusProposal(proposal.proposalId),
                              icon: const Icon(Icons.bolt_rounded, size: 16),
                              label: const Text('Execute on Solana (Consensus Met)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emerald,
                                foregroundColor: Colors.black87,
                                minimumSize: const Size.fromHeight(36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ] else if (isExecuted) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.emerald),
                                  SizedBox(width: 6),
                                  Text(
                                    'Executed & Sealed on Solana Devnet',
                                    style: TextStyle(fontSize: 10, color: AppColors.emerald, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

