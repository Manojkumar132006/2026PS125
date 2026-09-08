import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

void showCreateAssetModal(BuildContext context, SolanaService service) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _CreateAssetSheet(service: service),
  );
}

class _CreateAssetSheet extends StatefulWidget {
  final SolanaService service;

  const _CreateAssetSheet({required this.service});

  @override
  State<_CreateAssetSheet> createState() => _CreateAssetSheetState();
}

class _CreateAssetSheetState extends State<_CreateAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Nano-Tech Armor Protocol Key');
  final _descController = TextEditingController(
    text: 'Decentralized cryptographic access key for high-security neural and physical armory.',
  );
  String _assetType = 'Native PDA Asset';
  late OrgMember _selectedOwner;
  int _selectedColorIndex = 0;
  bool _isMinting = false;

  final List<Map<String, dynamic>> _iconOptions = [
    {'icon': Icons.vpn_key_rounded, 'color': const Color(0xFF6366F1), 'label': 'Key'},
    {'icon': Icons.dataset_rounded, 'color': const Color(0xFF06B6D4), 'label': 'Dataset'},
    {'icon': Icons.cloud_done_rounded, 'color': const Color(0xFF10B981), 'label': 'Cloud'},
    {'icon': Icons.security_rounded, 'color': const Color(0xFFA855F7), 'label': 'Security'},
  ];

  @override
  void initState() {
    super.initState();
    final members = widget.service.currentOrgMembers;
    _selectedOwner = members.isNotEmpty
        ? members.first
        : OrgMember(
            id: 'mem_default',
            name: 'Alex Chen',
            email: 'alex@acme.com',
            role: 'Admin',
            roleId: 1,
            permissionsMask: 0x3F,
            avatarColor: AppColors.primary,
            joinedAt: DateTime.now(),
            identityPda: 'id_pda_default',
          );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleMint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isMinting = true);

    final opt = _iconOptions[_selectedColorIndex];
    final success = await widget.service.createDigitalAsset(
      name: _nameController.text,
      type: _assetType,
      description: _descController.text,
      ownerIdentityPda: _selectedOwner.identityPda,
      ownerLabel: _selectedOwner.name,
      accentColor: opt['color'] as Color,
      icon: opt['icon'] as IconData,
      requiredPermission: 0x08,
    );

    if (mounted) {
      setState(() => _isMinting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Asset "${_nameController.text}" minted and assigned to ${_selectedOwner.name}!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final members = widget.service.currentOrgMembers;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar
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
                  const Text(
                    'Mint Program Asset PDA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textDim),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Asset Name
              const Text('Asset Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'e.g. Master Secret Key #1',
                  hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
                  prefixIcon: const Icon(Icons.token_rounded, color: AppColors.textDim, size: 18),
                  filled: true,
                  fillColor: AppColors.bgSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter asset name' : null,
              ),
              const SizedBox(height: 14),

              // Asset Type Dropdown
              const Text('Asset Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _assetType,
                    isExpanded: true,
                    dropdownColor: AppColors.bgCard,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textDim),
                    items: ['Native PDA Asset', 'AccessGrant PDA', 'Security Token PDA'].map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: const TextStyle(fontSize: 13, color: AppColors.textMain)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _assetType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Initial Assigned Owner
              const Text('Initial Owner (Identity PDA)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<OrgMember>(
                    value: members.contains(_selectedOwner) ? _selectedOwner : (members.isNotEmpty ? members.first : null),
                    isExpanded: true,
                    dropdownColor: AppColors.bgCard,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textDim),
                    items: members.map((m) {
                      return DropdownMenuItem<OrgMember>(
                        value: m,
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(color: m.avatarColor.withValues(alpha: 0.25), shape: BoxShape.circle),
                              child: Center(
                                child: Text(
                                  m.name.isNotEmpty ? m.name[0] : 'U',
                                  style: TextStyle(color: m.avatarColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${m.name} (${m.role})',
                                style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedOwner = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Visual Style / Accent
              const Text('Asset Accent & Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_iconOptions.length, (idx) {
                  final opt = _iconOptions[idx];
                  final isSelected = _selectedColorIndex == idx;
                  final color = opt['color'] as Color;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedColorIndex = idx),
                    child: Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.2) : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(opt['icon'] as IconData, color: color, size: 20),
                          const SizedBox(height: 4),
                          Text(opt['label'] as String, style: TextStyle(fontSize: 10, color: isSelected ? color : AppColors.textDim)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // Description
              const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Resource details and access parameters...',
                  hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.bgSecondary,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              // Fee Sponsorship Notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 16, color: AppColors.emerald),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '0.00 SOL Network Gas Fee (100% Sponsored by Org)',
                        style: TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: _isMinting ? null : _handleMint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isMinting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Mint & Assign On-Chain PDA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
