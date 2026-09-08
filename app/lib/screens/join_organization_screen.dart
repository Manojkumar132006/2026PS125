import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';
import 'create_organization_screen.dart';

class JoinOrganizationScreen extends StatefulWidget {
  final SolanaService service;

  const JoinOrganizationScreen({super.key, required this.service});

  @override
  State<JoinOrganizationScreen> createState() => _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  final _searchController = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    final success = await widget.service.joinOrganization(domainOrCode: query);

    if (mounted) {
      setState(() => _isJoining = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully joined ${widget.service.currentOrg?.name}!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Organization not found. Please enter a valid invite code or domain (e.g. company.com).';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final activeOrgId = service.currentOrg?.id;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        title: const Text(
          'Join Organization',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.cyan, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Decentralized Membership',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Join an organization using its corporate domain or unique invite code.',
                            style: TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Search / Code Input
              const Text(
                'Invite Code or Corporate Domain',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                      decoration: InputDecoration(
                        hintText: 'e.g. ACME-8921 or cyberdyne.io',
                        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
                        prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.textDim, size: 18),
                        filled: true,
                        fillColor: AppColors.bgCard,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cyan, width: 1.5)),
                      ),
                      onSubmitted: (val) => _handleJoin(val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isJoining ? null : () => _handleJoin(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isJoining
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                        : const Text('Join', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.rose, fontSize: 11)),
              ],
              const SizedBox(height: 24),

              // Verified Organizations Section
              const Text(
                'Available Verified Organizations',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 12),

              ...service.organizations.map((org) {
                final isCurrent = org.id == activeOrgId;
                return _OrgCard(
                  org: org,
                  isCurrent: isCurrent,
                  onSelect: () {
                    if (isCurrent) return;
                    service.switchOrganization(org.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Switched to ${org.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: AppColors.emerald,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }),

              const SizedBox(height: 20),

              // Create New Org Callout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_business_rounded, color: AppColors.primaryLight, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need a new workspace?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                          SizedBox(height: 2),
                          Text('Create an organization and become Authority.', style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateOrganizationScreen(service: service),
                          ),
                        );
                      },
                      child: const Text('Create', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  final OrganizationModel org;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _OrgCard({required this.org, required this.isCurrent, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: org.brandColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: org.brandColor.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    org.name.isNotEmpty ? org.name[0] : 'O',
                    style: TextStyle(color: org.brandColor, fontSize: 16, fontWeight: FontWeight.w800),
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
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.emerald)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(org.domain, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isCurrent)
                ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    foregroundColor: AppColors.primaryLight,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(60, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: const BorderSide(color: AppColors.borderHover),
                  ),
                  child: const Text('Switch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(org.description, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(4)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 12, color: AppColors.textDim),
                    const SizedBox(width: 4),
                    Text('${org.memberCount} members', style: const TextStyle(fontSize: 10, color: AppColors.textDim)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(4)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_gas_station_rounded, size: 12, color: AppColors.emerald),
                    const SizedBox(width: 4),
                    Text('◎ ${org.treasuryBalance.toStringAsFixed(1)} SOL', style: const TextStyle(fontSize: 10, color: AppColors.emerald, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              Text('Code: ${org.inviteCode}', style: AppTheme.mono(fontSize: 10, color: AppColors.textDim)),
            ],
          ),
        ],
      ),
    );
  }
}
