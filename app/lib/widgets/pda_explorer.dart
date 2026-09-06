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
        address: '768qPsmw2Rj... (Singleton)',
        properties: {
          'Authority': 'B7dKfnjjpBm... (Admin)',
          'Status': 'ACTIVE',
        },
        accentColor: AppColors.primary,
      ),
      PdaItem(
        title: 'Identity A PDA',
        seeds: '["identity", controllerA]',
        address: '9wQoR3P8v1m...',
        properties: {
          'Status': 'ACTIVE (1)',
          'Role': 'ASSET_MANAGER (0x2F)',
          'Balance': '0 SOL (Sponsored)',
        },
        accentColor: AppColors.cyan,
      ),
      PdaItem(
        title: 'Identity B PDA',
        seeds: '["identity", controllerB]',
        address: '4nLkpX7R9v2...',
        properties: {
          'Status': 'ACTIVE (1)',
          'Role': 'Standard Owner',
        },
        accentColor: AppColors.purple,
      ),
      PdaItem(
        title: 'Resource #1 PDA',
        seeds: '["resource", org, 1]',
        address: '5aRts89Lq0K...',
        properties: {
          'Owner': 'Identity B PDA',
          'Status': 'ACTIVE (1)',
          'Type': 'Non-NFT PDA Asset',
        },
        accentColor: AppColors.emerald,
      ),
      PdaItem(
        title: 'AccessGrant PDA',
        seeds: '["grant", identityA, res1, role]',
        address: '8bXym3Kp29v...',
        properties: {
          'Identity': 'Identity A',
          'Target': 'Resource #1',
          'Active': 'TRUE',
          'Expires': 'Never (0)',
        },
        accentColor: AppColors.amber,
      ),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pdas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final pda = pdas[index];
        return _PdaItemCard(pda: pda);
      },
    );
  }
}

class _PdaItemCard extends StatelessWidget {
  final PdaItem pda;

  const _PdaItemCard({required this.pda});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pda.accentColor.withValues(alpha: 0.25)),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: pda.accentColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pda.seeds,
                  style: AppTheme.mono(color: AppColors.textDim, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pda.properties.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                  Flexible(
                    child: Text(
                      e.value,
                      style: AppTheme.mono(
                        fontSize: 11,
                        color: e.value.contains('ACTIVE') || e.value.contains('TRUE')
                            ? AppColors.emerald
                            : AppColors.textMain,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
