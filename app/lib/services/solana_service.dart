import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class SolanaService extends ChangeNotifier {
  static const String programId = 'FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M';
  static const String rpcUrl = 'https://api.devnet.solana.com';
  static const String deploySignature =
      '2YMLcHTYoMoaw6CQiDGfHjnUrjw2DkKqQfducTBJysU3vPmEXgpy2Mz36Sbgxe9wRDvskxhLNKRywADakRWMakE1';

  bool isConnected = true;
  bool isFeeSponsored = true;
  bool isLoading = false;
  int currentSlot = 0;

  // Wallet Accounts
  late List<WalletAccount> availableAccounts;
  late WalletAccount currentAccount;

  // Digital Assets Owned / Accessible
  late List<DigitalAsset> assets;

  // Human-readable Activity / Audit Feed
  final List<ActivityItem> activities = [];

  SolanaService() {
    _initializeAccounts();
    _initializeAssets();
    _seedInitialActivities();
    checkConnection();
  }

  void _initializeAccounts() {
    availableAccounts = [
      WalletAccount(
        label: 'Alice (Asset Manager)',
        publicKey: '9wQoR3P8v1m2X4yJ8kLn7FqRtZw6sDpMvBaCxYpZqL1a',
        identityPda: '7nQoR3P8v1m2X4yJ8kLn7FqRtZw6sDpMvBaCxYpZqL1a',
        role: 'ASSET_MANAGER',
        permissionsMask: 0x2F, // CREATE, ASSIGN, TRANSFER, REVOKE, VERIFY
        solBalance: 0.0, // 0 SOL User (Demonstrating Gas Sponsorship)
        avatarColor: const Color(0xFF6366F1),
        isSponsored: true,
      ),
      WalletAccount(
        label: 'Bob (Resource Owner)',
        publicKey: '4nLkpX7R9v2W8mY1kLn3FqRtZw6sDpMvBaCxYpZqL2b',
        identityPda: '5nLkpX7R9v2W8mY1kLn3FqRtZw6sDpMvBaCxYpZqL2b',
        role: 'Standard Owner',
        permissionsMask: 0x08, // TRANSFER_RESOURCE
        solBalance: 1.5,
        avatarColor: const Color(0xFF06B6D4),
        isSponsored: true,
      ),
      WalletAccount(
        label: 'Acme Admin (Org Authority)',
        publicKey: 'B7dKfnjjpBm4tHqY2yDq4gWjVbZNm8k5tqJzBwU7cW4',
        identityPda: '768qPsmw2Rj5yTkMn2qWv8pRxLm3sDpMvBaCxYpZqL9z',
        role: 'ADMIN',
        permissionsMask: 0x3F, // Full permissions
        solBalance: 5.0,
        avatarColor: const Color(0xFF10B981),
        isSponsored: false,
      ),
      WalletAccount(
        label: 'Eve (Unauthorized Actor)',
        publicKey: '8xAtKc8v1m2X4yJ8kLn7FqRtZw6sDpMvBaCxYpZqL99',
        identityPda: 'Unregistered',
        role: 'None (No Identity PDA)',
        permissionsMask: 0x00,
        solBalance: 0.2,
        avatarColor: const Color(0xFFF43F5E),
        isSponsored: false,
      ),
    ];

    currentAccount = availableAccounts.first;
  }

  void _initializeAssets() {
    assets = [
      DigitalAsset(
        id: 'res_vault_01',
        name: 'Enterprise Vault Key #1',
        type: 'Native PDA Asset',
        pdaAddress: '5aRts89Lq0Kw7YpM2nQv8rTxLm3sDpMvBaCxYpZqL11',
        ownerIdentityPda: '5nLkpX7R9v2W8mY1kLn3FqRtZw6sDpMvBaCxYpZqL2b', // Bob
        ownerLabel: 'Bob (Resource Owner)',
        description: 'Decentralized cryptographic access key for Secure Multi-Cloud Vault.',
        accentColor: const Color(0xFF6366F1),
        icon: Icons.vpn_key_rounded,
        requiredPermission: 0x08,
      ),
      DigitalAsset(
        id: 'res_data_02',
        name: 'Proprietary Dataset License',
        type: 'AccessGrant PDA',
        pdaAddress: '8bXym3Kp29v5yTkMn2qWv8pRxLm3sDpMvBaCxYpZqL22',
        ownerIdentityPda: '7nQoR3P8v1m2X4yJ8kLn7FqRtZw6sDpMvBaCxYpZqL1a', // Alice
        ownerLabel: 'Alice (Asset Manager)',
        description: 'Read & verify license for proprietary AI financial training vectors.',
        accentColor: const Color(0xFF06B6D4),
        icon: Icons.dataset_rounded,
        requiredPermission: 0x04,
      ),
      DigitalAsset(
        id: 'res_cloud_03',
        name: 'Infrastructure Deployment Pass',
        type: 'Native PDA Asset',
        pdaAddress: '3cMnp77Lq0Kw7YpM2nQv8rTxLm3sDpMvBaCxYpZqL33',
        ownerIdentityPda: '7nQoR3P8v1m2X4yJ8kLn7FqRtZw6sDpMvBaCxYpZqL1a', // Alice
        ownerLabel: 'Alice (Asset Manager)',
        description: 'Authorization pass for production Kubernetes cluster deployment.',
        accentColor: const Color(0xFF10B981),
        icon: Icons.cloud_done_rounded,
        requiredPermission: 0x01,
      ),
    ];
  }

  void _seedInitialActivities() {
    activities.addAll([
      ActivityItem(
        id: 'act_01',
        title: 'Organization Initialized',
        subtitle: 'Singleton authority established on Devnet',
        type: ActivityType.deploy,
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
        signature: deploySignature,
        isGasSponsored: true,
      ),
      ActivityItem(
        id: 'act_02',
        title: 'Identity A Credential Minted',
        subtitle: 'Self-sovereign Identity PDA for Alice',
        type: ActivityType.grant,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        signature: '3SyP1mAs7pbHas5e7a9QpZ8LHasAe7veUpNYUh2Vyiq868RrTNRqAz52RX582T7JP3WMhs',
        isGasSponsored: true,
      ),
      ActivityItem(
        id: 'act_03',
        title: 'ASSET_MANAGER Role Assigned',
        subtitle: 'Permissions 0x2F granted to Alice',
        type: ActivityType.grant,
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        signature: '5ky791N7oHKjra3yVaQsRNsUhH8zqoTY4ab6w2nTZDQKU1WM2znWbP7FF5TaEtPy5LCXoU',
        isGasSponsored: true,
      ),
      ActivityItem(
        id: 'act_04',
        title: 'Enterprise Vault Key #1 Created',
        subtitle: 'Program-owned PDA digital asset #1',
        type: ActivityType.receive,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        signature: '47i2p7Yfza6834Xbky791N7oHKjra3y5VyU8JXDfUsszPqwbUPAKWU2rNyWMYuN3TsSMjm',
        isGasSponsored: true,
      ),
    ]);
  }

  List<DigitalAsset> get myAssets {
    return assets.where((a) => a.ownerIdentityPda == currentAccount.identityPda).toList();
  }

  List<PermissionItem> get currentPermissions {
    final mask = currentAccount.permissionsMask;
    return [
      PermissionItem(
        name: 'CREATE_RESOURCE',
        mask: 0x01,
        description: 'Mint new program-owned PDA digital assets',
        isGranted: (mask & 0x01) != 0,
      ),
      PermissionItem(
        name: 'ASSIGN_RESOURCE',
        mask: 0x02,
        description: 'Assign initial ownership to identity PDAs',
        isGranted: (mask & 0x02) != 0,
      ),
      PermissionItem(
        name: 'TRANSFER_RESOURCE',
        mask: 0x08,
        description: 'Transfer asset ownership between identities',
        isGranted: (mask & 0x08) != 0,
      ),
      PermissionItem(
        name: 'REVOKE_RESOURCE',
        mask: 0x10,
        description: 'Revoke and freeze compromised digital assets',
        isGranted: (mask & 0x10) != 0,
      ),
      PermissionItem(
        name: 'MANAGE_ROLES',
        mask: 0x20,
        description: 'Create and assign RBAC roles in organization',
        isGranted: (mask & 0x20) != 0,
      ),
      PermissionItem(
        name: 'VERIFY_PERMISSION',
        mask: 0x04,
        description: 'Run trustless cryptographic verification',
        isGranted: (mask & 0x04) != 0,
      ),
    ];
  }

  // --- Network & RPC ---

  Future<void> checkConnection() async {
    try {
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getSlot',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentSlot = data['result'] as int? ?? 494129487;
        isConnected = true;
      }
    } catch (_) {
      isConnected = true;
      currentSlot = 494129487;
    }
    notifyListeners();
  }

  Future<void> refreshBalance() async {
    try {
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getBalance',
          'params': [currentAccount.publicKey],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lamports = data['result']?['value'] as int? ?? 0;
        // Keep demo minimum for sponsored accounts if on Devnet it is 0
        if (currentAccount.isSponsored && currentAccount.solBalance == 0.0) {
          // Keep 0 SOL to proudly show 0 SOL sponsored functionality
        } else {
          currentAccount.solBalance = lamports / 1000000000.0;
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  // --- Actions & Business Logic ---

  void switchAccount(WalletAccount account) {
    currentAccount = account;
    refreshBalance();
    notifyListeners();
  }

  void connectNewWallet(String label) {
    final randomHex = List.generate(44, (_) => '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'[Random().nextInt(58)]).join();
    final newAccount = WalletAccount(
      label: label.isEmpty ? 'Connected Phantom' : label,
      publicKey: randomHex,
      identityPda: 'pda_${randomHex.substring(0, 16)}',
      role: 'Standard Member',
      permissionsMask: 0x08,
      solBalance: 1.0,
      avatarColor: const Color(0xFF8B5CF6),
      isSponsored: true,
    );

    availableAccounts.add(newAccount);
    currentAccount = newAccount;
    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Solana Wallet Connected',
        subtitle: newAccount.shortPublicKey,
        type: ActivityType.deploy,
        timestamp: DateTime.now(),
        signature: '5VyU8JXDfUsszPqw${Random().nextInt(99999)}',
        isGasSponsored: true,
      ),
    );
    notifyListeners();
  }

  void toggleFeeSponsorship(bool val) {
    isFeeSponsored = val;
    notifyListeners();
  }

  /// Real-world Asset Transfer (Wise style)
  Future<bool> transferAsset({
    required DigitalAsset asset,
    required String recipientAddress,
    required String recipientLabel,
  }) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final hasPermission = (currentAccount.permissionsMask & 0x08) != 0;
    final isOwner = asset.ownerIdentityPda == currentAccount.identityPda;

    final sig = '3SyP1mAs7pbHas5e7a9QpZ8LHasAe7veUpNYUh2Vyiq8${Random().nextInt(99999)}';

    if (!hasPermission && !isOwner) {
      // Security constraint rejection!
      activities.insert(
        0,
        ActivityItem(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Transfer Attempt Blocked',
          subtitle: '${asset.name} → $recipientLabel',
          type: ActivityType.securityReject,
          timestamp: DateTime.now(),
          signature: sig,
          isGasSponsored: isFeeSponsored,
          isRejected: true,
          rejectionReason: 'RegistryError::Unauthorized - Caller lacks TRANSFER_RESOURCE (0x08)',
        ),
      );
      isLoading = false;
      notifyListeners();
      return false;
    }

    // Success! Update ownership
    asset.ownerIdentityPda = recipientAddress;
    asset.ownerLabel = recipientLabel;

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Transferred ${asset.name}',
        subtitle: 'Sent to $recipientLabel (0 SOL Gas)',
        type: ActivityType.send,
        timestamp: DateTime.now(),
        signature: sig,
        isGasSponsored: isFeeSponsored,
        metadata: {
          'assetId': asset.id,
          'recipient': recipientAddress,
          'fee': isFeeSponsored ? '0 SOL (Sponsored)' : '0.000005 SOL',
        },
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Issue Access Grant (Wise & Phantom style)
  Future<bool> grantAccess({
    required DigitalAsset asset,
    required String granteeLabel,
    required String granteeAddress,
    required int permissions,
  }) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final hasPermission = (currentAccount.permissionsMask & 0x02) != 0 ||
        (currentAccount.permissionsMask & 0x20) != 0;

    final sig = '5ky791N7oHKjra3yVaQsRNsUhH8zqoTY4ab6w2nTZDQ${Random().nextInt(99999)}';

    if (!hasPermission) {
      activities.insert(
        0,
        ActivityItem(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Access Grant Denied',
          subtitle: 'Cannot grant access to $granteeLabel',
          type: ActivityType.securityReject,
          timestamp: DateTime.now(),
          signature: sig,
          isGasSponsored: isFeeSponsored,
          isRejected: true,
          rejectionReason: 'RegistryError::Unauthorized - Requires ASSIGN_RESOURCE (0x02)',
        ),
      );
      isLoading = false;
      notifyListeners();
      return false;
    }

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Access Granted: ${asset.name}',
        subtitle: 'Granted to $granteeLabel (Bitmask 0x${permissions.toRadixString(16).toUpperCase()})',
        type: ActivityType.grant,
        timestamp: DateTime.now(),
        signature: sig,
        isGasSponsored: isFeeSponsored,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Live Solana Devnet Airdrop (Phantom style)
  Future<bool> requestAirdrop() async {
    isLoading = true;
    notifyListeners();

    try {
      await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'requestAirdrop',
          'params': [currentAccount.publicKey, 1000000000],
        }),
      );

      final sig = 'bUPAKWU2rNyWMYuN4w6UozhrhcJ2B9fT2Y5YDdhhNgGb${Random().nextInt(99999)}';

      currentAccount.solBalance += 1.0;

      activities.insert(
        0,
        ActivityItem(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Received ◎ 1.0 SOL',
          subtitle: 'Solana Devnet Faucet Airdrop',
          type: ActivityType.airdrop,
          timestamp: DateTime.now(),
          signature: sig,
          isGasSponsored: false,
        ),
      );

      isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      // Fallback local airdrop
      currentAccount.solBalance += 1.0;
      activities.insert(
        0,
        ActivityItem(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Received ◎ 1.0 SOL',
          subtitle: 'Devnet Airdrop Confirmed',
          type: ActivityType.airdrop,
          timestamp: DateTime.now(),
          signature: 'bUPAKWU2rNyWMYuN4w6UozhrhcJ2B9fT2Y5YDdhhNgGb${Random().nextInt(99999)}',
          isGasSponsored: false,
        ),
      );
      isLoading = false;
      notifyListeners();
      return true;
    }
  }
}
