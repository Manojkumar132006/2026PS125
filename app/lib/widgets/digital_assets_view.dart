import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';
import 'create_asset_modal.dart';
import 'transfer_modal.dart';
import 'ownership_provenance_modal.dart';

class DigitalAssetsView extends StatefulWidget {
  final SolanaService service;

  const DigitalAssetsView({super.key, required this.service});

  @override
  State<DigitalAssetsView> createState() => _DigitalAssetsViewState();
}

class _DigitalAssetsViewState extends State<DigitalAssetsView> {
  int _selectedFilter = 0; // 0 = My Assets, 1 = All Assets

  @override
  Widget build(BuildContext context) {
    final myAssets = widget.service.myAssets;
    final allAssets = widget.service.assets;
    final displayedAssets = _selectedFilter == 0 ? myAssets : allAssets;
    final canCreate = (widget.service.currentUser?.permissionsMask ?? 0) & 0x01 != 0 ||
        (widget.service.currentUser?.isAdmin ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header & Filter Tabs (Wise style)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Digital Assets',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            Row(
              children: [
                if (canCreate) ...[
                  InkWell(
                    onTap: () => showCreateAssetModal(context, widget.service),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: AppColors.cyan),
                          SizedBox(width: 2),
                          Text('Mint', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.cyan)),
                        ],
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _FilterTab(
                        label: 'Mine (${myAssets.length})',
                        isSelected: _selectedFilter == 0,
                        onTap: () => setState(() => _selectedFilter = 0),
                      ),
                      _FilterTab(
                        label: 'All (${allAssets.length})',
                        isSelected: _selectedFilter == 1,
                        onTap: () => setState(() => _selectedFilter = 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (displayedAssets.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.token_outlined, size: 36, color: AppColors.textDim),
                const SizedBox(height: 10),
                const Text(
                  'No assets assigned to this identity',
                  style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Switch accounts or transfer an asset to view it here.',
                  style: TextStyle(color: AppColors.textDim, fontSize: 11),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedAssets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final asset = displayedAssets[index];
              return _AssetCard(
                asset: asset,
                isOwner: asset.ownerIdentityPda == widget.service.currentUser?.identityPda,
                onTap: () => _showAssetDetailsModal(context, asset),
                onProvenanceTap: () => showOwnershipProvenanceModal(context, asset: asset, service: widget.service),
              );
            },
          ),
      ],
    );
  }

  void _showAssetDetailsModal(BuildContext context, DigitalAsset asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isOwner = asset.ownerIdentityPda == widget.service.currentUser?.identityPda;

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

              // Title Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: asset.accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(asset.icon, color: asset.accentColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                        ),
                        Text(
                          asset.type,
                          style: TextStyle(fontSize: 11, color: asset.accentColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ACTIVE', style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(asset.description, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
              const SizedBox(height: 16),

              // Details List
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'On-Chain PDA',
                      value: asset.pdaAddress,
                      isCopyable: true,
                    ),
                    const Divider(height: 14, color: AppColors.border),
                    _DetailRow(
                      label: 'Current Owner',
                      value: asset.ownerLabel,
                    ),
                    const Divider(height: 14, color: AppColors.border),
                    _DetailRow(
                      label: 'Required Permission',
                      value: 'TRANSFER_RESOURCE (0x08)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ownership History & Provenance Action
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showOwnershipProvenanceModal(context, asset: asset, service: widget.service);
                },
                icon: const Icon(Icons.history_edu_rounded, size: 18, color: AppColors.cyan),
                label: const Text(
                  'View Ownership History & Provenance',
                  style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.cyan, width: 1.2),
                  backgroundColor: AppColors.cyan.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),

              // Actions
              if (isOwner) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showTransferModal(context, widget.service);
                  },
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.white),
                  label: const Text('Transfer Ownership', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.borderHover),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(color: AppColors.textMain)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryLight : AppColors.textDim,
          ),
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final DigitalAsset asset;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onProvenanceTap;

  const _AssetCard({
    required this.asset,
    required this.isOwner,
    required this.onTap,
    required this.onProvenanceTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOwner ? asset.accentColor.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: asset.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(asset.icon, color: asset.accentColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          asset.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OWNED',
                            style: TextStyle(fontSize: 9, color: AppColors.primaryLight, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Owner: ${asset.ownerLabel}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Quick Provenance Button
            IconButton(
              icon: const Icon(Icons.history_edu_rounded, size: 20, color: AppColors.cyan),
              tooltip: 'View Ownership History',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onProvenanceTap,
            ),
            const SizedBox(width: 4),

            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCopyable;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isCopyable = false,
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
                  value.length > 20 ? '${value.substring(0, 8)}...${value.substring(value.length - 8)}' : value,
                  style: AppTheme.mono(fontSize: 11, color: AppColors.textMain),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 4),
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
