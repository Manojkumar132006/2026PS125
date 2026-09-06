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
      title: 'Solana Identity & RBAC',
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
      backgroundColor: AppColors.bgPrimary,
      appBar: NetworkHeader(service: _solanaService),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Minimal Metrics Bar
              MetricsGrid(isFeeSponsored: _solanaService.isFeeSponsored),
              const SizedBox(height: 14),

              // Active Tab Content
              if (_currentTab == 0)
                ScenarioView(service: _solanaService)
              else if (_currentTab == 1)
                OperatorConsole(service: _solanaService)
              else if (_currentTab == 2)
                const PdaExplorerView()
              else
                AuditTrailView(service: _solanaService),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        backgroundColor: AppColors.bgSecondary,
        indicatorColor: AppColors.primary.withValues(alpha: 0.25),
        height: 62,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.playlist_play_rounded, size: 20),
            selectedIcon: Icon(Icons.playlist_play_rounded, color: AppColors.primaryLight, size: 20),
            label: 'Scenarios',
          ),
          const NavigationDestination(
            icon: Icon(Icons.terminal_rounded, size: 20),
            selectedIcon: Icon(Icons.terminal_rounded, color: AppColors.primaryLight, size: 20),
            label: 'Console',
          ),
          const NavigationDestination(
            icon: Icon(Icons.data_object_rounded, size: 20),
            selectedIcon: Icon(Icons.data_object_rounded, color: AppColors.primaryLight, size: 20),
            label: 'PDAs',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('${_solanaService.auditEvents.length}'),
              isLabelVisible: _solanaService.auditEvents.isNotEmpty,
              child: const Icon(Icons.history_rounded, size: 20),
            ),
            selectedIcon: Badge(
              label: Text('${_solanaService.auditEvents.length}'),
              isLabelVisible: _solanaService.auditEvents.isNotEmpty,
              child: const Icon(Icons.history_rounded, color: AppColors.primaryLight, size: 20),
            ),
            label: 'Audit',
          ),
        ],
      ),
    );
  }
}
