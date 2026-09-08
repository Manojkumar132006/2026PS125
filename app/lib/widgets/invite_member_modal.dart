import 'package:flutter/material.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

void showInviteMemberModal(BuildContext context, SolanaService service) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _InviteMemberSheet(service: service),
  );
}

class _InviteMemberSheet extends StatefulWidget {
  final SolanaService service;

  const _InviteMemberSheet({required this.service});

  @override
  State<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<_InviteMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Peter Parker');
  final _emailController = TextEditingController();
  String _selectedRole = 'Asset Manager';
  int _permissionsMask = 0x2F;
  bool _isInviting = false;

  final Map<String, int> _roleMasks = {
    'Admin': 0x3F,
    'Asset Manager': 0x2F,
    'Auditor': 0x24,
    'Enterprise Member': 0x0F,
  };

  @override
  void initState() {
    super.initState();
    final domain = widget.service.currentOrg?.domain ?? 'acmecorp.com';
    _emailController.text = 'peter.parker@$domain';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isInviting = true);

    final success = await widget.service.inviteMember(
      name: _nameController.text,
      email: _emailController.text,
      role: _selectedRole,
      permissionsMask: _permissionsMask,
    );

    if (mounted) {
      setState(() => _isInviting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_nameController.text} invited as $_selectedRole (0x${_permissionsMask.toRadixString(16).toUpperCase()})',
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

              // Title & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Invite Member to Organization',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textDim),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full Name
              const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'e.g. Peter Parker',
                  hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textDim, size: 18),
                  filled: true,
                  fillColor: AppColors.bgSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter name' : null,
              ),
              const SizedBox(height: 14),

              // Work Email
              const Text('Corporate Work Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'e.g. colleague@company.com',
                  hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
                  prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textDim, size: 18),
                  filled: true,
                  fillColor: AppColors.bgSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter email';
                  if (!val.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Role Selector Chips
              const Text('Assign RBAC Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _roleMasks.keys.map((role) {
                  final isSelected = _selectedRole == role;
                  return ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedRole = role;
                          _permissionsMask = _roleMasks[role]!;
                        });
                      }
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    backgroundColor: AppColors.bgSecondary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Permissions Preview Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'On-Chain Permissions',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                        Text(
                          'Bitmask: 0x${_permissionsMask.toRadixString(16).toUpperCase()}',
                          style: AppTheme.mono(fontSize: 11, color: AppColors.cyan, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PermissionChip(name: 'CREATE_RESOURCE (0x01)', granted: (_permissionsMask & 0x01) != 0),
                    _PermissionChip(name: 'ASSIGN_RESOURCE (0x02)', granted: (_permissionsMask & 0x02) != 0),
                    _PermissionChip(name: 'TRANSFER_RESOURCE (0x08)', granted: (_permissionsMask & 0x08) != 0),
                    _PermissionChip(name: 'REVOKE_RESOURCE (0x10)', granted: (_permissionsMask & 0x10) != 0),
                    _PermissionChip(name: 'MANAGE_ROLES (0x20)', granted: (_permissionsMask & 0x20) != 0),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Button
              ElevatedButton(
                onPressed: _isInviting ? null : _handleInvite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isInviting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Invite & Assign Role', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  final String name;
  final bool granted;

  const _PermissionChip({required this.name, required this.granted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: granted ? AppColors.emerald : AppColors.textDim,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: granted ? AppColors.textMain : AppColors.textDim,
              fontWeight: granted ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
