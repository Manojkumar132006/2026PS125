import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/biometric_service.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';
import 'ownership_provenance_modal.dart';

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
  final TextEditingController _recipientCtrl = TextEditingController(text: 'sarah.chen@acme.com');
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.service.assets.first;
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    super.dispose();
  }

  Future<void> _startBiometricTransfer(BuildContext context) async {
    final recipient = _recipientCtrl.text.trim();
    if (recipient.isEmpty) {
      setState(() => _errorMessage = 'Please enter a recipient email or address.');
      return;
    }

    setState(() => _errorMessage = null);

    try {
      final authenticated = await BiometricService.authenticate(
        reason: widget.isGrantMode
            ? 'Touch fingerprint sensor to authorize access grant for "${_selectedAsset.name}" to $recipient'
            : 'Touch fingerprint sensor to sign transfer of "${_selectedAsset.name}" to $recipient',
      );

      if (!authenticated) {
        setState(() {
          _errorMessage = 'Biometric authentication cancelled. Fingerprint verification is required to sign.';
        });
        return;
      }

      final ok = await widget.service.transferAsset(
        asset: _selectedAsset,
        recipientAddress: 'pda_$recipient',
        recipientLabel: recipient,
      );

      if (ok) {
        setState(() => _isSuccess = true);
      } else {
        setState(() {
          _errorMessage = 'On-chain execution blocked: Caller lacks required permission bitmask.';
        });
      }
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled' || e.code == 'PasscodeNotSet') {
        setState(() {
          _errorMessage = 'No fingerprint enrolled on device. Please enroll a fingerprint in Android Settings > Security > Fingerprint, or test using emulator controls.';
        });
      } else {
        setState(() {
          _errorMessage = 'Biometric error (${e.code}): ${e.message}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric authentication failed: $e';
      });
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fingerprint_rounded, size: 14, color: AppColors.purple),
                  SizedBox(width: 6),
                  Text(
                    'Biometric Signature Verified (Secure Enclave)',
                    style: TextStyle(fontSize: 11, color: AppColors.purple, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                showOwnershipProvenanceModal(context, asset: _selectedAsset, service: widget.service);
              },
              icon: const Icon(Icons.history_edu_rounded, size: 16, color: AppColors.cyan),
              label: const Text('View Immutable Provenance Trail', style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.cyan),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
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

          // 1. Select Asset
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
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                showOwnershipProvenanceModal(context, asset: _selectedAsset, service: widget.service);
              },
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_edu_rounded, size: 13, color: AppColors.cyan),
                    SizedBox(width: 4),
                    Text(
                      'View Ownership Provenance',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.cyan),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Recipient Input
          const Text('Recipient (Work Email or Solana Public Key)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim)),
          const SizedBox(height: 6),
          TextField(
            controller: _recipientCtrl,
            style: const TextStyle(color: AppColors.textMain, fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_search_rounded, size: 18, color: AppColors.textDim),
              hintText: 'colleague@acmecorp.com or Solana Address',
              hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
              filled: true,
              fillColor: AppColors.bgSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickRecipientChip(
                  label: 'sarah.chen@acme.com',
                  onTap: () => setState(() => _recipientCtrl.text = 'sarah.chen@acme.com'),
                ),
                const SizedBox(width: 6),
                _QuickRecipientChip(
                  label: 'devops-vault@acme.com',
                  onTap: () => setState(() => _recipientCtrl.text = 'devops-vault@acme.com'),
                ),
                const SizedBox(width: 6),
                _QuickRecipientChip(
                  label: 'security@acme.com',
                  onTap: () => setState(() => _recipientCtrl.text = 'security@acme.com'),
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
                _FeeRow(label: 'Recipient', value: _recipientCtrl.text.isNotEmpty ? _recipientCtrl.text : 'None'),
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

          // Confirm Button with Biometric Hardware Gating
          ElevatedButton.icon(
            onPressed: widget.service.isLoading ? null : () => _startBiometricTransfer(context),
            icon: const Icon(Icons.fingerprint_rounded, size: 18),
            label: Text(
              widget.isGrantMode ? 'Sign with Fingerprint & Grant' : 'Sign with Fingerprint & Transfer',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickRecipientChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickRecipientChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.cyan, fontWeight: FontWeight.w500),
        ),
      ),
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


