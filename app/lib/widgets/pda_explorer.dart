import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class PdaExplorerView extends StatelessWidget {
  const PdaExplorerView({super.key});

  @override
  Widget build(BuildContext context) {
    final pdas = [
      PdaItem(
        title: 'Organization PDA',
        seeds: '["organization"]',
        address: '768qPsmw2Rj5X9Y... (Program Singleton)',
        properties: {
          'Authority': 'B7dKfnjjpBmYrakj5j44nF4moQpZ8LHasAe7veUpNYUh',
          'Role Registry': 'Active',
          'Bump': '255',
        },
        accentColor: AppColors.primary,
      ),
      PdaItem(
        title: 'Identity PDA (Identity A)',
        seeds: '["identity", controller_pubkey]',
        address: '9wQoR3P8v1m... (Self-Sovereign Identity)',
        properties: {
          'Controller': 'UserA_5PCfvf... (Client-Side Keypair)',
          'Status': 'ACTIVE (1)',
          'Assigned Role': 'ASSET_MANAGER (Perms: 0x2F)',
          'User Balance': '0 SOL (Gas Sponsored)',
        },
        accentColor: AppColors.cyan,
      ),
      PdaItem(
        title: 'Role PDA (ASSET_MANAGER)',
        seeds: '["role", organization, 2]',
        address: '2yFmk8W9x7q... (RBAC Role Account)',
        properties: {
          'Role ID': '2 (ASSET_MANAGER)',
          'Permission Bitmask': '0x2F (CREATE | ASSIGN | TRANSFER | REVOKE | VERIFY)',
          'Bit 0 (Create)': '1',
          'Bit 1 (Assign)': '1',
          'Bit 2 (Transfer)': '1',
          'Bit 3 (Revoke)': '1',
          'Bit 5 (Verify)': '1',
        },
        accentColor: AppColors.purple,
      ),
      PdaItem(
        title: 'Resource #1 PDA',
        seeds: '["resource", organization, 1]',
        address: '5aRts89Lq0K... (Native Digital Asset)',
        properties: {
          'Resource ID': '1',
          'Owner': 'Identity B PDA (Transferred)',
          'Status': 'ACTIVE (1)',
          'Type': '1 (Custom Program Asset)',
          'NFT / SPL Standard': 'None (Pure Solana PDA)',
        },
        accentColor: AppColors.emerald,
      ),
      PdaItem(
        title: 'AccessGrant PDA',
        seeds: '["grant", identity, resource, role]',
        address: '8bXym3Kp29v... (Resource Access Token)',
        properties: {
          'Identity': 'Identity A PDA',
          'Target Resource': 'Resource #1 PDA',
          'Role': 'ASSET_MANAGER PDA',
          'Active': 'TRUE',
          'Expires At': '0 (Permanent Grant)',
        },
        accentColor: AppColors.amber,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('On-Chain PDA State Explorer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Live persistent accounts derived and owned exclusively by the Anchor program.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('5 PDAs Derived', style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.7 : 1.9,
                ),
                itemCount: pdas.length,
                itemBuilder: (context, index) {
                  final pda = pdas[index];
                  return _PdaCard(pda: pda);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PdaCard extends StatelessWidget {
  final PdaItem pda;

  const _PdaCard({required this.pda});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pda.accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pda.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: pda.accentColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pda.seeds,
                  style: AppTheme.mono(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(pda.address, style: AppTheme.mono(color: AppColors.textDim, fontSize: 11)),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: pda.properties.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                      Text(
                        entry.value,
                        style: AppTheme.mono(
                          fontSize: 11,
                          color: entry.value.contains('ACTIVE') || entry.value.contains('TRUE')
                              ? AppColors.emerald
                              : AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
