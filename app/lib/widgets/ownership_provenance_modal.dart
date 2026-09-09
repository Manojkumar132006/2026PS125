import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

void showOwnershipProvenanceModal(
  BuildContext context, {
  required DigitalAsset asset,
  required SolanaService service,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _OwnershipProvenanceSheet(asset: asset, service: service),
  );
}

class _OwnershipProvenanceSheet extends StatelessWidget {
  final DigitalAsset asset;
  final SolanaService service;

  const _OwnershipProvenanceSheet({
    required this.asset,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final history = service.getAssetOwnershipHistory(asset.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDim.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title bar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: asset.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: asset.accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Icon(asset.icon, color: asset.accentColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Asset Provenance',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded, size: 12, color: AppColors.emerald),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Immutable PDA Chain',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          asset.name,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: asset.accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PDA: ${asset.shortPda}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(color: AppColors.border),
              const SizedBox(height: 14),

              // Overview stat row
              Row(
                children: [
                  _buildStatCard(
                    title: 'Current Owner',
                    value: asset.ownerLabel,
                    subtitle: asset.ownerIdentityPda.isNotEmpty
                        ? (asset.ownerIdentityPda.length > 12
                            ? '${asset.ownerIdentityPda.substring(0, 5)}...${asset.ownerIdentityPda.substring(asset.ownerIdentityPda.length - 4)}'
                            : asset.ownerIdentityPda)
                        : 'Unassigned',
                    color: AppColors.cyan,
                    icon: Icons.person_pin_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: 'Ownership Transitions',
                    value: '${history.length} Event${history.length == 1 ? '' : 's'}',
                    subtitle: history.isNotEmpty
                        ? 'Seq #0 to #${history.last.sequence}'
                        : 'No transfers yet',
                    color: AppColors.primary,
                    icon: Icons.history_edu_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Provenance Stepped Timeline
              Row(
                children: [
                  const Icon(Icons.timeline_rounded, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'HISTORICAL OWNERSHIP AUDIT TRAIL',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'No ownership transitions recorded yet.',
                      style: GoogleFonts.outfit(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final isFirst = index == 0;
                    final isLast = index == history.length - 1;

                    return _buildTimelineItem(context, item, isFirst: isFirst, isLast: isLast);
                  },
                ),

              const SizedBox(height: 18),

              // Cryptographic Guarantee Explainer Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.cyan.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: AppColors.primaryLight, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Decentralized Provenance Guarantee',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Every ownership transition is atomically committed into a unique on-chain OwnershipRecord PDA with deterministic seeds. No administrative or compromised key can rewrite past transfers or forge sequence history.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    OwnershipRecordModel item, {
    required bool isFirst,
    required bool isLast,
  }) {
    final isGenesis = item.sequence == 0;
    final badgeColor = isGenesis ? AppColors.emerald : AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator line + circle
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '#${item.sequence}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLast ? badgeColor.withValues(alpha: 0.4) : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Type badge + Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGenesis ? Icons.auto_awesome_rounded : Icons.swap_horiz_rounded,
                              size: 12,
                              color: badgeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.transferType,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTimestamp(item.timestamp),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Previous -> New Owner Flow
                  if (!isGenesis) ...[
                    Row(
                      children: [
                        Text(
                          'From: ',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                        ),
                        Expanded(
                          child: Text(
                            item.previousOwnerLabel,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Text(
                        isGenesis ? 'Minted to: ' : 'To: ',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Expanded(
                        child: Text(
                          item.newOwnerLabel,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isLast ? AppColors.emerald : AppColors.textMain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Identity PDA: ${item.shortNewOwner}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      color: AppColors.textDim,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bottom badges & Tx Signature
                  Row(
                    children: [
                      // Biometric badge
                      if (item.isBiometricVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fingerprint_rounded, size: 12, color: AppColors.cyan),
                              const SizedBox(width: 3),
                              Text(
                                'Biometric Signed',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (item.isGasSponsored)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '0 SOL Gas',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emerald,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // Tx signature copy button
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: item.txSignature));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction signature copied to clipboard'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.copy_rounded, size: 10, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                item.shortTxSignature,
                                style: GoogleFonts.robotoMono(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
