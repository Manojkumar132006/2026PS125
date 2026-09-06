import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MetricsGrid extends StatelessWidget {
  const MetricsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isWide ? 2.1 : 1.6,
          children: const [
            _MetricCard(
              title: 'Self-Sovereign Identity',
              value: 'Controller PDAs',
              subtitle: 'Zero Personal Data On-Chain',
              accentColor: AppColors.primary,
              icon: Icons.fingerprint_rounded,
            ),
            _MetricCard(
              title: 'Digital Asset Ownership',
              value: 'Native PDAs',
              subtitle: 'Non-NFT / Zero Metaplex Bloat',
              accentColor: AppColors.cyan,
              icon: Icons.token_rounded,
            ),
            _MetricCard(
              title: 'Trustless Authorization',
              value: '64-Bit Bitmask',
              subtitle: 'Runtime Enforced RBAC',
              accentColor: AppColors.emerald,
              icon: Icons.admin_panel_settings_rounded,
            ),
            _MetricCard(
              title: 'Fee Sponsorship',
              value: '0 SOL Users',
              subtitle: 'Organization Gas Relaying',
              accentColor: AppColors.amber,
              icon: Icons.flash_on_rounded,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
