import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

void showTransferModal(BuildContext context, SolanaService service, {bool isGrantMode = false}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _TransferSheet(service: service, isGrantMode: isGrantMode),
  );
}

class _TransferSheet extends StatefulWidget {
  final SolanaService service;
  final bool isGrantMode;

  const _TransferSheet({required this.service, this.isGrantMode = false});

  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  late DigitalAsset _selectedAsset;
  String _selectedRecipientLabel = 'Bob (Resource Owner)';
  String _selectedRecipientAddress = '5nLkpX7R9v2W8mY1kLn3FqRtZw6sDpMvBaCxYpZqL2b';
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.service.assets.first;
    // Set default recipient to someone other than current user
    if (widget.service.currentAccount.label.startsWith('Bob')) {
      _selectedRecipientLabel = 'Alice (Asset Manager)';
      _selectedRecipientAddress = '7nQoR3P8v1m2X4yJ8kLn7FqRtZw6sDpMvBaCxYpZqL1a';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.emerald, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.emerald, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isGrantMode ? 'Access Permission Granted!' : 'Asset Transferred Successfully!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'On-chain transaction committed to Solana Devnet.\nGas fee paid by Organization: 0 SOL charged to you.',
              style: const TextStyle(fontSize: 13, color: AppColors.textDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

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
              Text(
                widget.isGrantMode ? 'Grant On-Chain Access' : 'Transfer Digital Asset',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textDim),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Select Asset (Wise card dropdown)
          const Text('Select Asset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DigitalAsset>(
                value: _selectedAsset,
                isExpanded: true,
                dropdownColor: AppColors.bgSecondary,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textDim),
                items: widget.service.assets.map((asset) {
                  return DropdownMenuItem(
                    value: asset,
                    child: Row(
                      children: [
                        Icon(asset.icon, size: 18, color: asset.accentColor),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            asset.name,
                            style: const TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAsset = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Select Recipient
          const Text('Recipient Identity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _RecipientChip(
                  label: 'Bob (Owner)',
                  address: '5nLkpX7R9v2W8mY1kLn3FqRtZw6sDpMvBaCxYpZqL2b',
                  isSelected: _selectedRecipientLabel == 'Bob (Resource Owner)',
                  onTap: () {
                    setState(() {
                      _selectedRecipientLabel = 'Bob (Resource Owner)';
                      _selectedRecipientAddress = '5nLkpX7R9v2W8mY1kLn3FqRtZw6sDpMvBaCxYpZqL2b';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _RecipientChip(
                  label: 'Alice (Manager)',
                  address: '7nQoR3P8v1m2X4yJ8kLn7FqRtZw6sDpMvBaCxYpZqL1a',
                  isSelected: _selectedRecipientLabel == 'Alice (Asset Manager)',
                  onTap: () {
                    setState(() {
                      _selectedRecipientLabel = 'Alice (Asset Manager)';
                      _selectedRecipientAddress = '7nQoR3P8v1m2X4yJ8kLn7FqRtZw6sDpMvBaCxYpZqL1a';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _RecipientChip(
                  label: 'Identity C',
                  address: '3cRts89Lq0Kw7YpM2nQv8rTxLm3sDpMvBaCxYpZqL33',
                  isSelected: _selectedRecipientLabel == 'Identity C',
                  onTap: () {
                    setState(() {
                      _selectedRecipientLabel = 'Identity C';
                      _selectedRecipientAddress = '3cRts89Lq0Kw7YpM2nQv8rTxLm3sDpMvBaCxYpZqL33';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Wise-Style Fee Transparency Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _FeeRow(label: 'Transfer Item', value: _selectedAsset.name),
                const SizedBox(height: 8),
                _FeeRow(label: 'To Identity', value: _selectedRecipientLabel),
                const Divider(height: 16, color: AppColors.border),
                _FeeRow(
                  label: 'Network Gas Fee',
                  value: '◎ 0.00 SOL',
                  valueColor: AppColors.emerald,
                  isBold: true,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: AppColors.emerald),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        '100% Sponsored by Acme Organization',
                        style: TextStyle(fontSize: 11, color: AppColors.textDim),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.rose.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.rose),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Confirm Button
          ElevatedButton(
            onPressed: widget.service.isLoading
                ? null
                : () async {
                    setState(() => _errorMessage = null);
                    bool ok = false;
                    if (widget.isGrantMode) {
                      ok = await widget.service.grantAccess(
                        asset: _selectedAsset,
                        granteeAddress: _selectedRecipientAddress,
                        granteeLabel: _selectedRecipientLabel,
                        permissions: 0x08,
                      );
                    } else {
                      ok = await widget.service.transferAsset(
                        asset: _selectedAsset,
                        recipientAddress: _selectedRecipientAddress,
                        recipientLabel: _selectedRecipientLabel,
                      );
                    }

                    if (ok) {
                      setState(() => _isSuccess = true);
                    } else {
                      setState(() {
                        _errorMessage =
                            'On-chain execution blocked: Caller lacks required permission bitmask.';
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: widget.service.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    widget.isGrantMode ? 'Confirm Access Grant' : 'Confirm & Transfer Asset',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecipientChip extends StatelessWidget {
  final String label;
  final String address;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecipientChip({
    required this.label,
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.25),
      backgroundColor: AppColors.bgSecondary,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _FeeRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppColors.textMain,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
