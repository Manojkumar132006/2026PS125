import 'package:flutter/material.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class AuditTrailView extends StatelessWidget {
  final SolanaService service;

  const AuditTrailView({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    if (service.auditEvents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text('No events recorded yet.', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: service.auditEvents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final ev = service.auditEvents[index];
        final isReject = ev.name.contains('Blocked') || ev.name.contains('Unauthorized');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isReject ? AppColors.rose.withValues(alpha: 0.3) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isReject
                      ? AppColors.rose.withValues(alpha: 0.15)
                      : AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ev.name,
                  style: TextStyle(
                    color: isReject ? AppColors.rose : AppColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(ev.timeFormatted, style: AppTheme.mono(color: AppColors.textDim, fontSize: 10)),
              const Spacer(),
              Text(
                'tx:${ev.signature.substring(0, 5)}...',
                style: AppTheme.mono(color: AppColors.primaryLight, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }
}
