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
      children: [
        // Persona Switcher & Controls Card
        Container(
          padding: const EdgeInsets.all(18),
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
                  const Text('Live Operator Console', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Actor: ${service.activePersona.displayName}',
                      style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Persona Selectors
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ActorPersona.values.map((p) {
                  final isSelected = service.activePersona == p;
                  final isAttacker = p == ActorPersona.attacker;

                  return ChoiceChip(
                    label: Text(p.displayName, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    selected: isSelected,
                    onSelected: (_) => service.setPersona(p),
                    selectedColor: isAttacker ? AppColors.rose.withOpacity(0.25) : AppColors.primary.withOpacity(0.25),
                    backgroundColor: AppColors.bgSecondary,
                    side: BorderSide(
                      color: isSelected
                          ? (isAttacker ? AppColors.rose : AppColors.primary)
                          : AppColors.border,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),

              // Action Trigger Buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ActionButton(
                    label: 'Verify Permission (require_permission)',
                    icon: Icons.verified_user_rounded,
                    color: AppColors.emerald,
                    onTap: () => service.executeManualAction('Verify Permission'),
                  ),
                  _ActionButton(
                    label: 'Transfer Resource #1',
                    icon: Icons.swap_horiz_rounded,
                    color: AppColors.cyan,
                    onTap: () => service.executeManualAction('Transfer Resource'),
                  ),
                  _ActionButton(
                    label: 'Revoke Resource #1',
                    icon: Icons.block_rounded,
                    color: AppColors.rose,
                    onTap: () => service.executeManualAction('Revoke Resource'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Terminal Log Card
        Container(
          height: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF06070B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      const Text('Runtime Output Console', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                    ],
                  ),
                  const Text('solana-devnet', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: service.consoleLogs.length,
                  itemBuilder: (context, index) {
                    final log = service.consoleLogs[index];
                    final isError = log.contains('REJECTED') || log.contains('❌');
                    final isSuccess = log.contains('✔') || log.contains('confirmed') || log.contains('passed');

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log,
                        style: AppTheme.mono(
                          fontSize: 11,
                          color: isError
                              ? AppColors.rose
                              : isSuccess
                                  ? AppColors.emerald
                                  : AppColors.textMuted,
                        ),
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.12),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
