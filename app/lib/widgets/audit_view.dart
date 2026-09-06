import 'package:flutter/material.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class AuditTrailView extends StatelessWidget {
  final SolanaService service;

  const AuditTrailView({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
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
                  const Text('Immutable Anchor Audit Trail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Events emitted by the Solana program and verified via transaction logs.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${service.auditEvents.length} Events Logged', style: const TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          if (service.auditEvents.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No audit events yet. Run the Acceptance Test to emit on-chain events.', style: TextStyle(color: AppColors.textDim)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: service.auditEvents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ev = service.auditEvents[index];
                final isReject = ev.name.contains('Blocked') || ev.name.contains('Unauthorized');

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isReject ? AppColors.rose.withOpacity(0.3) : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isReject ? AppColors.rose.withOpacity(0.15) : AppColors.cyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ev.name,
                          style: TextStyle(
                            color: isReject ? AppColors.rose : AppColors.cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(ev.timeFormatted, style: AppTheme.mono(color: AppColors.textDim, fontSize: 11)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          ev.payload.toString(),
                          style: AppTheme.mono(color: AppColors.textMuted, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'tx:${ev.signature.substring(0, 8)}...',
                        style: AppTheme.mono(color: AppColors.primaryLight, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
