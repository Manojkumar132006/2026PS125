import 'package:flutter/material.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class CreateOrganizationScreen extends StatefulWidget {
  final SolanaService service;

  const CreateOrganizationScreen({super.key, required this.service});

  @override
  State<CreateOrganizationScreen> createState() => _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Stark Enterprises');
  final _domainController = TextEditingController(text: 'starkindustries.io');
  final _descController = TextEditingController(
    text: 'Decentralized advanced defense, clean energy, and hardware enclaves.',
  );
  double _initialDepositSol = 5.0;
  bool _isDeploying = false;

  @override
  void dispose() {
    _nameController.dispose();
    _domainController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isDeploying = true);

    final success = await widget.service.createOrganization(
      name: _nameController.text,
      domain: _domainController.text,
      initialDepositSol: _initialDepositSol,
      description: _descController.text,
    );

    if (mounted) {
      setState(() => _isDeploying = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Organization "${_nameController.text}" initialized with Super Admin role!',
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
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        title: const Text(
          'Create Organization',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.cyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'On-Chain Authority Setup',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Initializes singleton authority PDA on Solana Devnet with 100% gas sponsorship.',
                              style: TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Organization Name
                const Text('Organization Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'e.g. Acme Corporation',
                    hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
                    prefixIcon: const Icon(Icons.apartment_rounded, color: AppColors.textDim, size: 18),
                    filled: true,
                    fillColor: AppColors.bgCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter organization name' : null,
                ),
                const SizedBox(height: 18),

                // Corporate Domain
                const Text('Corporate Domain', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _domainController,
                  style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'e.g. acmecorp.com',
                    hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
                    prefixIcon: const Icon(Icons.language_rounded, color: AppColors.textDim, size: 18),
                    filled: true,
                    fillColor: AppColors.bgCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter corporate domain';
                    if (!val.contains('.')) return 'Enter a valid domain (e.g. company.com)';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Description
                const Text('Organization Purpose / Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'Brief description of the organization and its assets...',
                    hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.bgCard,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),

                // Initial Gas Sponsorship Fund
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gas Sponsorship Treasury', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    Text('◎ ${_initialDepositSol.toStringAsFixed(1)} SOL', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emerald)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [1.0, 5.0, 10.0, 25.0].map((amt) {
                    final isSelected = _initialDepositSol == amt;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _initialDepositSol = amt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.bgCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${amt.toInt()} SOL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Super Admin Role Designation Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, color: AppColors.purple, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Your Designated Role',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMain),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Super Admin (0x3F)', style: TextStyle(color: AppColors.purple, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'As creator, you will hold full authority to invite users, assign 64-bit RBAC roles, mint PDA assets, and manage the treasury.',
                        style: TextStyle(fontSize: 11, color: AppColors.textDim, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // Submit Button
                ElevatedButton(
                  onPressed: _isDeploying ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isDeploying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Initialize Organization on Devnet',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
