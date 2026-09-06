import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class ScenarioView extends StatelessWidget {
  final SolanaService service;

  const ScenarioView({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action Button
        ElevatedButton.icon(
          onPressed: service.isRunningScenario ? null : () => service.runAcceptanceScenario(),
          icon: service.isRunningScenario
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.play_arrow_rounded, size: 20),
          label: Text(
            service.isRunningScenario ? 'Running On-Chain Test...' : 'Run 17-Step Acceptance Test',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 14),

        // Steps List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: service.steps.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final s = service.steps[index];
            return _StepCard(step: s);
          },
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final ScenarioStep step;

  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final isRunning = step.status == StepStatus.running;
    final isPassed = step.status == StepStatus.passed;
    final isSecurityReject = step.step == 11 || step.step == 12 || step.step == 15 || step.step == 16;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isRunning
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRunning
              ? AppColors.primary
              : isPassed
                  ? (isSecurityReject
                      ? AppColors.rose.withValues(alpha: 0.3)
                      : AppColors.emerald.withValues(alpha: 0.3))
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Step Circle
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPassed
                  ? (isSecurityReject
                      ? AppColors.rose.withValues(alpha: 0.2)
                      : AppColors.emerald.withValues(alpha: 0.2))
                  : isRunning
                      ? AppColors.amber.withValues(alpha: 0.2)
                      : AppColors.bgSecondary,
              border: Border.all(
                color: isPassed
                    ? (isSecurityReject ? AppColors.rose : AppColors.emerald)
                    : isRunning
                        ? AppColors.amber
                        : AppColors.border,
              ),
            ),
            child: Center(
              child: isRunning
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.amber),
                    )
                  : isPassed
                      ? Icon(
                          isSecurityReject ? Icons.shield_rounded : Icons.check_rounded,
                          size: 14,
                          color: isSecurityReject ? AppColors.rose : AppColors.emerald,
                        )
                      : Text(
                          '${step.step}',
                          style: const TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
            ),
          ),
          const SizedBox(width: 10),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${step.step}. ${step.title}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isPassed ? AppColors.textMain : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (step.note != null)
                  Text(
                    step.note!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSecurityReject ? AppColors.rose : AppColors.emerald,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Short TX Badge
          if (step.txSignature != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'tx:${step.txSignature!.substring(0, 5)}...',
                style: AppTheme.mono(color: AppColors.primaryLight, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
