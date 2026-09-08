import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

void showAssignRoleModal(BuildContext context, SolanaService service, OrgMember member) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AssignRoleSheet(service: service, member: member),
  );
}

class _AssignRoleSheet extends StatefulWidget {
  final SolanaService service;
  final OrgMember member;

  const _AssignRoleSheet({required this.service, required this.member});

  @override
  State<_AssignRoleSheet> createState() => _AssignRoleSheetState();
}

class _AssignRoleSheetState extends State<_AssignRoleSheet> {
  late String _currentRole;
  late int _permissionsMask;
  bool _isSaving = false;

  final Map<String, int> _presets = {
    'Super Admin': 0x3F,
    'Asset Manager': 0x2F,
    'Auditor': 0x24,
    'Enterprise Member': 0x0F,
  };

  @override
  void initState() {
    super.initState();
    _currentRole = widget.member.role;
    _permissionsMask = widget.member.permissionsMask;
  }

  void _toggleBit(int bit) {
    setState(() {
      _permissionsMask ^= bit;
      // sync role name if matches a preset
      bool matched = false;
      for (final entry in _presets.entries) {
        if (entry.value == _permissionsMask) {
          _currentRole = entry.key;
          matched = true;
          break;
        }
      }
      if (!matched) {
        _currentRole = 'Custom (0x${_permissionsMask.toRadixString(16).toUpperCase()})';
      }
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final success = await widget.service.updateMemberRole(
      memberId: widget.member.id,
      newRole: _currentRole,
      newMask: _permissionsMask,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.member.name} updated to $_currentRole (0x${_permissionsMask.toRadixString(16).toUpperCase()})',
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
    final member = widget.member;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Role & On-Chain RBAC',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textDim),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Member Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: member.avatarColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: member.avatarColor),
                    ),
                    child: Center(
                      child: Text(
                        member.name.isNotEmpty ? member.name[0] : 'U',
                        style: TextStyle(color: member.avatarColor, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                        Text(member.email, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('0x${_permissionsMask.toRadixString(16).toUpperCase()}',
                        style: AppTheme.mono(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preset Roles
            const Text('Preset Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.keys.map((role) {
                final isSelected = _permissionsMask == _presets[role];
                return ChoiceChip(
                  label: Text(role),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentRole = role;
                        _permissionsMask = _presets[role]!;
                      });
                    }
                  },
                  selectedColor: AppColors.purple.withValues(alpha: 0.25),
                  backgroundColor: AppColors.bgSecondary,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.purple : AppColors.textMuted,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.purple : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Granular Bitmask Permissions
            const Text('Granular 64-Bit Bitmask Permissions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _BitmaskSwitch(
                    title: 'CREATE_RESOURCE (0x01)',
                    subtitle: 'Mint new program-owned PDA assets',
                    isChecked: (_permissionsMask & 0x01) != 0,
                    onToggle: () => _toggleBit(0x01),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _BitmaskSwitch(
                    title: 'ASSIGN_RESOURCE (0x02)',
                    subtitle: 'Assign asset ownership to identity PDAs',
                    isChecked: (_permissionsMask & 0x02) != 0,
                    onToggle: () => _toggleBit(0x02),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _BitmaskSwitch(
                    title: 'TRANSFER_RESOURCE (0x08)',
                    subtitle: 'Transfer asset ownership between identities',
                    isChecked: (_permissionsMask & 0x08) != 0,
                    onToggle: () => _toggleBit(0x08),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _BitmaskSwitch(
                    title: 'REVOKE_RESOURCE (0x10)',
                    subtitle: 'Freeze and revoke compromised assets',
                    isChecked: (_permissionsMask & 0x10) != 0,
                    onToggle: () => _toggleBit(0x10),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _BitmaskSwitch(
                    title: 'MANAGE_ROLES (0x20)',
                    subtitle: 'Assign & revoke organization RBAC roles',
                    isChecked: (_permissionsMask & 0x20) != 0,
                    onToggle: () => _toggleBit(0x20),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _BitmaskSwitch(
                    title: 'VERIFY_PERMISSION (0x04)',
                    subtitle: 'Execute trustless cryptographic verification',
                    isChecked: (_permissionsMask & 0x04) != 0,
                    onToggle: () => _toggleBit(0x04),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Role On-Chain', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BitmaskSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isChecked;
  final VoidCallback onToggle;

  const _BitmaskSwitch({
    required this.title,
    required this.subtitle,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textDim)),
                ],
              ),
            ),
            Checkbox(
              value: isChecked,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.emerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }
}
