import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'services/solana_service.dart';
import 'theme/app_theme.dart';
import 'widgets/wallet_header.dart';
import 'widgets/balance_card.dart';
import 'widgets/digital_assets_view.dart';
import 'widgets/identity_pass_view.dart';
import 'widgets/admin_hub_view.dart';
import 'widgets/activity_feed_view.dart';

void main() {
  runApp(const SolanaIdentityApp());
}

class SolanaIdentityApp extends StatelessWidget {
  const SolanaIdentityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solana Identity & Wallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final SolanaService _solanaService = SolanaService();

  @override
  void initState() {
    super.initState();
    _solanaService.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_solanaService.isAuthenticated) {
      return AuthScreen(service: _solanaService);
    }
    return ConsumerDashboard(service: _solanaService);
  }
}

class ConsumerDashboard extends StatefulWidget {
  final SolanaService service;

  const ConsumerDashboard({super.key, required this.service});

  @override
  State<ConsumerDashboard> createState() => _ConsumerDashboardState();
}

class _ConsumerDashboardState extends State<ConsumerDashboard> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: WalletHeader(service: service),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_currentTab == 0) ...[
                // Home: Balance Hero, Quick Actions, Assets, Recent Activity
                BalanceCard(service: service),
                const SizedBox(height: 18),
                DigitalAssetsView(service: service),
                const SizedBox(height: 20),
                ActivityFeedView(service: service),
              ] else if (_currentTab == 1) ...[
                // Assets Tab
                DigitalAssetsView(service: service),
              ] else if (_currentTab == 2) ...[
                // Identity Pass & RBAC Tab
                IdentityPassView(service: service),
              ] else if (_currentTab == 3) ...[
                // Admin Hub & Governance Tab
                AdminHubView(service: service),
              ] else ...[
                // Activity Tab
                ActivityFeedView(service: service),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        backgroundColor: AppColors.bgSecondary,
        indicatorColor: AppColors.primary.withValues(alpha: 0.25),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined, size: 20),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryLight, size: 20),
            label: 'Wallet',
          ),
          const NavigationDestination(
            icon: Icon(Icons.token_outlined, size: 20),
            selectedIcon: Icon(Icons.token_rounded, color: AppColors.primaryLight, size: 20),
            label: 'Assets',
          ),
          const NavigationDestination(
            icon: Icon(Icons.badge_outlined, size: 20),
            selectedIcon: Icon(Icons.badge_rounded, color: AppColors.primaryLight, size: 20),
            label: 'Identity',
          ),
          const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined, size: 20),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryLight, size: 20),
            label: 'Admin',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, size: 20),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primaryLight, size: 20),
            label: 'Activity',
          ),
        ],
      ),
    );
  }
}
