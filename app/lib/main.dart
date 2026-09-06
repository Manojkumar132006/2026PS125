import 'package:flutter/material.dart';
import 'services/solana_service.dart';
import 'theme/app_theme.dart';
import 'widgets/network_header.dart';
import 'widgets/metrics_grid.dart';
import 'widgets/scenario_view.dart';
import 'widgets/operator_console.dart';
import 'widgets/pda_explorer.dart';
import 'widgets/audit_view.dart';

void main() {
  runApp(const SolanaIdentityApp());
}

class SolanaIdentityApp extends StatelessWidget {
  const SolanaIdentityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solana Decentralized Identity & RBAC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SolanaService _solanaService = SolanaService();
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _solanaService.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Network & Program Header
          NetworkHeader(service: _solanaService),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // High-level Architecture Metrics
                  const MetricsGrid(),
                  const SizedBox(height: 20),

                  // Navigation Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TabButton(
                          label: '17-Step Acceptance Scenario',
                          icon: Icons.checklist_rounded,
                          isSelected: _currentTab == 0,
                          onTap: () => setState(() => _currentTab = 0),
                        ),
                        _TabButton(
                          label: 'PDA State Explorer',
                          icon: Icons.account_tree_rounded,
                          isSelected: _currentTab == 1,
                          onTap: () => setState(() => _currentTab = 1),
                        ),
                        _TabButton(
                          label: 'Immutable Audit Trail (${_solanaService.auditEvents.length})',
                          icon: Icons.receipt_long_rounded,
                          isSelected: _currentTab == 2,
                          onTap: () => setState(() => _currentTab = 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Active Tab Content
                  if (_currentTab == 0)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 1000;

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: ScenarioView(service: _solanaService)),
                              const SizedBox(width: 20),
                              Expanded(flex: 2, child: OperatorConsole(service: _solanaService)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              ScenarioView(service: _solanaService),
                              const SizedBox(height: 20),
                              OperatorConsole(service: _solanaService),
                            ],
                          );
                        }
                      },
                    )
                  else if (_currentTab == 1)
                    const PdaExplorerView()
                  else
                    AuditTrailView(service: _solanaService),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
