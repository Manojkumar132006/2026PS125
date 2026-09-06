import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class ScenarioView extends StatelessWidget {
  final SolanaService service;

  const ScenarioView({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '17-Step Acceptance Scenario',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Section 12 Spec',
                            style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'End-to-end decentralized identity, RBAC, access control, and revocation test.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),

                ElevatedButton.icon(
                  onPressed: service.isRunningScenario ? null : () => service.runAcceptanceScenario(),
                  icon: service.isRunningScenario
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(service.isRunningScenario ? 'Running On-Chain...' : '▶ Run Full Acceptance Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // Scrollable Steps List
          ListView.separated(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: service.steps.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final s = service.steps[index];
              return _StepItem(step: s);
            },
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final ScenarioStep step;

  const _StepItem({required this.step});

  @override
  Widget build(BuildContext context) {
    final isRunning = step.status == StepStatus.running;
    final isPassed = step.status == StepStatus.passed;
    final isSecurityReject = step.step == 11 || step.step == 12 || step.step == 15 || step.step == 16;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isRunning
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRunning
              ? AppColors.primary
              : isPassed
                  ? (isSecurityReject ? AppColors.rose.withOpacity(0.3) : AppColors.border)
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Step Circle Indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPassed
                  ? (isSecurityReject ? AppColors.rose.withOpacity(0.2) : AppColors.emerald.withOpacity(0.2))
                  : isRunning
                      ? AppColors.amber.withOpacity(0.2)
                      : AppColors.bgCard,
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
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber),
                    )
                  : isPassed
                      ? Icon(
                          isSecurityReject ? Icons.security_rounded : Icons.check_rounded,
                          size: 16,
                          color: isSecurityReject ? AppColors.rose : AppColors.emerald,
                        )
                      : Text(
                          '${step.step}',
                          style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPassed ? AppColors.textMain : AppColors.textMuted,
                      ),
                    ),
                    if (step.eventName != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          step.eventName!,
                          style: AppTheme.mono(color: AppColors.cyan, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                ),
                if (step.note != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    step.note!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSecurityReject ? AppColors.rose : AppColors.emerald,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tx Signature Link
          if (step.txSignature != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(
                    'tx:${step.txSignature!.substring(0, 6)}...',
                    style: AppTheme.mono(color: AppColors.primaryLight, fontSize: 11),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new_rounded, size: 12, color: AppColors.primaryLight),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
