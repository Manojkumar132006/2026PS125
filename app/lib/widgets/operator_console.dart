import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class OperatorConsole extends StatelessWidget {
  final SolanaService service;

  const OperatorConsole({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Persona Selector Card
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
              const Text('Active Persona', style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              // Horizontally Scrollable Persona Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ActorPersona.values.map((p) {
                    final isSelected = service.activePersona == p;
                    final isAttacker = p == ActorPersona.attacker;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          p.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => service.setPersona(p),
                        selectedColor: isAttacker
                            ? AppColors.rose.withValues(alpha: 0.25)
                            : AppColors.primary.withValues(alpha: 0.25),
                        backgroundColor: AppColors.bgSecondary,
                        side: BorderSide(
                          color: isSelected
                              ? (isAttacker ? AppColors.rose : AppColors.primary)
                              : AppColors.border,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CompactBtn(
                    label: 'Verify Permission',
                    color: AppColors.emerald,
                    icon: Icons.verified_user_rounded,
                    onTap: () => service.executeManualAction('Verify Permission'),
                  ),
                  _CompactBtn(
                    label: 'Transfer Asset',
                    color: AppColors.cyan,
                    icon: Icons.swap_horiz_rounded,
                    onTap: () => service.executeManualAction('Transfer Resource'),
                  ),
                  _CompactBtn(
                    label: 'Revoke Asset',
                    color: AppColors.rose,
                    icon: Icons.block_rounded,
                    onTap: () => service.executeManualAction('Revoke Resource'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Terminal Log Card
        Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF06070B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Runtime Console', style: TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.w600)),
                  Text('${service.consoleLogs.length} logs', style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.builder(
                  itemCount: service.consoleLogs.length,
                  itemBuilder: (context, index) {
                    final log = service.consoleLogs[index];
                    final isError = log.contains('REJECTED') || log.contains('❌');
                    final isSuccess = log.contains('✔') || log.contains('confirmed') || log.contains('passed');

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        log,
                        style: AppTheme.mono(
                          fontSize: 10,
                          color: isError
                              ? AppColors.rose
                              : isSuccess
                                  ? AppColors.emerald
                                  : AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _CompactBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
