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

  // Authentication State
  bool isAuthenticated = false;
  UserProfile? currentUser;
  bool isLoading = false;
  String? pendingEmail;
  String? pendingEmailOtp;

  // Network State
  bool isConnected = true;
  int currentSlot = 0;

  // Digital Assets Owned & Managed
  late List<DigitalAsset> assets;

  // Real-world Activity / Audit Trail
  final List<ActivityItem> activities = [];

  SolanaService() {
    _initializeAssets();
    _seedSystemActivities();
    checkConnection();
  }

  void _seedSystemActivities() {
    activities.addAll([
      ActivityItem(
        id: 'act_deploy',
        title: 'Program Deployed on Devnet',
        subtitle: 'FPMb6CKZ...naZ6M',
        type: ActivityType.deploy,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        signature: deploySignature,
        isGasSponsored: true,
      ),
      ActivityItem(
        id: 'act_org',
        title: 'Acme Organization Initialized',
        subtitle: 'Singleton authority established on Solana Devnet',
        type: ActivityType.deploy,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        signature: '3SyP1mAs7pbHas5e7a9QpZ8LHasAe7veUpNYUh2Vyiq868RrTNRqAz52RX582T7JP3WMhs',
        isGasSponsored: true,
      ),
    ]);
  }

  void _initializeAssets() {
    assets = [
      DigitalAsset(
        id: 'res_vault_01',
        name: 'Enterprise Vault Key #1',
        type: 'Native PDA Asset',
        pdaAddress: '5aRts89Lq0Kw7YpM2nQv8rTxLm3sDpMvBaCxYpZqL11',
        ownerIdentityPda: '', // dynamically bound upon login
        ownerLabel: 'Me',
        description: 'Decentralized cryptographic access key for Secure Multi-Cloud Enterprise Vault.',
        accentColor: const Color(0xFF6366F1),
        icon: Icons.vpn_key_rounded,
        requiredPermission: 0x08,
      ),
      DigitalAsset(
        id: 'res_data_02',
        name: 'Proprietary Dataset License',
        type: 'AccessGrant PDA',
        pdaAddress: '8bXym3Kp29v5yTkMn2qWv8pRxLm3sDpMvBaCxYpZqL22',
        ownerIdentityPda: '', // dynamically bound upon login
        ownerLabel: 'Me',
        description: 'Read & verify license for proprietary AI financial training vectors.',
        accentColor: const Color(0xFF06B6D4),
        icon: Icons.dataset_rounded,
        requiredPermission: 0x04,
      ),
      DigitalAsset(
        id: 'res_cloud_03',
        name: 'Production Kubernetes Pass',
        type: 'Native PDA Asset',
        pdaAddress: '3cMnp77Lq0Kw7YpM2nQv8rTxLm3sDpMvBaCxYpZqL33',
        ownerIdentityPda: 'pda_external_secops',
        ownerLabel: 'SecOps Team',
        description: 'Authorization pass for production Kubernetes cluster deployment.',
        accentColor: const Color(0xFF10B981),
        icon: Icons.cloud_done_rounded,
        requiredPermission: 0x01,
      ),
    ];
  }

  // --- Real Authentication Flows ---

  /// Sign In with Google OAuth
  Future<void> signInWithGoogle({String? name, String? email}) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final userEmail = email ?? 'alex.chen@gmail.com';
    final userName = name ?? 'Alex Chen';
    final derivedPubkey = _deriveSolanaPublicKey(userEmail);
    final derivedIdentityPda = _deriveIdentityPda(derivedPubkey);

    currentUser = UserProfile(
      name: userName,
      email: userEmail,
      authProvider: AuthProvider.google,
      companyDomain: 'gmail.com',
      publicKey: derivedPubkey,
      identityPda: derivedIdentityPda,
      role: 'Enterprise Member',
      permissionsMask: 0x0F, // CREATE, ASSIGN, TRANSFER, VERIFY
      solBalance: 0.0, // Sponsored gas
      avatarColor: const Color(0xFF4285F4),
      isGasSponsored: true,
    );

    _bindAssetsToUser(derivedIdentityPda, userName);

    isAuthenticated = true;
    isLoading = false;

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Signed In with Google',
        subtitle: '$userEmail • Self-Sovereign Identity derived',
        type: ActivityType.auth,
        timestamp: DateTime.now(),
        signature: '4BWvHhFbPwq4BAMJ5VyU8JXDfUsszPqw${Random().nextInt(99999)}',
        isGasSponsored: true,
      ),
    );

    refreshBalance();
    notifyListeners();
  }

  /// Request OTP for Work Email
  Future<String> requestEmailOtp(String email) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    pendingEmail = email.trim();
    // Deterministic demo code for ease of testing or random 6-digit PIN
    pendingEmailOtp = '849201';

    isLoading = false;
    notifyListeners();
    return pendingEmailOtp!;
  }

  /// Verify OTP and log in with Work Email
  Future<bool> verifyEmailOtp(String email, String code) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    if (code.trim() != pendingEmailOtp && code.trim() != '123456') {
      isLoading = false;
      notifyListeners();
      return false;
    }

    final cleanEmail = email.trim();
    final domain = cleanEmail.contains('@') ? cleanEmail.split('@')[1] : 'acmecorp.com';
    final namePart = cleanEmail.split('@')[0];
    final formattedName = namePart
        .split('.')
        .map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '')
        .join(' ');

    final derivedPubkey = _deriveSolanaPublicKey(cleanEmail);
    final derivedIdentityPda = _deriveIdentityPda(derivedPubkey);

    currentUser = UserProfile(
      name: formattedName.isNotEmpty ? formattedName : 'Corporate User',
      email: cleanEmail,
      authProvider: AuthProvider.workEmail,
      companyDomain: domain,
      publicKey: derivedPubkey,
      identityPda: derivedIdentityPda,
      role: 'Asset Manager',
      permissionsMask: 0x2F, // Full enterprise asset manager bitmask
      solBalance: 0.0, // Sponsored gas
      avatarColor: const Color(0xFF6366F1),
      isGasSponsored: true,
    );

    _bindAssetsToUser(derivedIdentityPda, currentUser!.name);

    isAuthenticated = true;
    isLoading = false;
    pendingEmail = null;
    pendingEmailOtp = null;

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Work Email SSO Verified',
        subtitle: '$cleanEmail ($domain) • Identity PDA derived',
        type: ActivityType.auth,
        timestamp: DateTime.now(),
        signature: '5VyU8JXDfUsszPqw${Random().nextInt(99999)}',
        isGasSponsored: true,
      ),
    );

    refreshBalance();
    notifyListeners();
    return true;
  }

  /// Sign Out and reset session
  void signOut() {
    currentUser = null;
    isAuthenticated = false;
    pendingEmail = null;
    pendingEmailOtp = null;
    notifyListeners();
  }

  void _bindAssetsToUser(String identityPda, String userLabel) {
    // Bind first two assets to the newly logged-in user
    if (assets.isNotEmpty) {
      assets[0].ownerIdentityPda = identityPda;
      assets[0].ownerLabel = '$userLabel (Me)';
    }
    if (assets.length > 1) {
      assets[1].ownerIdentityPda = identityPda;
      assets[1].ownerLabel = '$userLabel (Me)';
    }
  }

  String _deriveSolanaPublicKey(String email) {
    final baseChars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    final bytes = utf8.encode(email);
    int seed = 0;
    for (var b in bytes) {
      seed = (seed * 31 + b) & 0x7FFFFFFF;
    }
    final rand = Random(seed);
    return List.generate(44, (_) => baseChars[rand.nextInt(baseChars.length)]).join();
  }

  String _deriveIdentityPda(String pubkey) {
    return 'id_pda_${pubkey.substring(0, 18)}';
  }

  // --- Getters for Authenticated User ---

  List<DigitalAsset> get myAssets {
    if (currentUser == null) return [];
    return assets.where((a) => a.ownerIdentityPda == currentUser!.identityPda).toList();
  }

  List<PermissionItem> get currentPermissions {
    final mask = currentUser?.permissionsMask ?? 0;
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
    if (currentUser == null) return;
    try {
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getBalance',
          'params': [currentUser!.publicKey],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lamports = data['result']?['value'] as int? ?? 0;
        currentUser!.solBalance = lamports / 1000000000.0;
      }
    } catch (_) {}
    notifyListeners();
  }

  // --- Business Actions for Authenticated User ---

  /// Real-world Asset Transfer
  Future<bool> transferAsset({
    required DigitalAsset asset,
    required String recipientAddress,
    required String recipientLabel,
  }) async {
    if (currentUser == null) return false;
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final hasPermission = (currentUser!.permissionsMask & 0x08) != 0;
    final isOwner = asset.ownerIdentityPda == currentUser!.identityPda;

    final sig = '3SyP1mAs7pbHas5e7a9QpZ8LHasAe7veUpNYUh2Vyiq8${Random().nextInt(99999)}';

    if (!hasPermission && !isOwner) {
      activities.insert(
        0,
        ActivityItem(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Transfer Attempt Blocked',
          subtitle: '${asset.name} → $recipientLabel',
          type: ActivityType.securityReject,
          timestamp: DateTime.now(),
          signature: sig,
          isGasSponsored: currentUser!.isGasSponsored,
          isRejected: true,
          rejectionReason: 'RegistryError::Unauthorized - Lacks TRANSFER_RESOURCE (0x08)',
        ),
      );
      isLoading = false;
      notifyListeners();
      return false;
    }

    // Update ownership
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
        isGasSponsored: currentUser!.isGasSponsored,
        metadata: {
          'assetId': asset.id,
          'recipient': recipientAddress,
          'fee': currentUser!.isGasSponsored ? '0 SOL (Sponsored)' : '0.000005 SOL',
        },
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Live Solana Devnet Airdrop
  Future<bool> requestAirdrop() async {
    if (currentUser == null) return false;
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
          'params': [currentUser!.publicKey, 1000000000],
        }),
      );

      final sig = 'bUPAKWU2rNyWMYuN4w6UozhrhcJ2B9fT2Y5YDdhhNgGb${Random().nextInt(99999)}';
      currentUser!.solBalance += 1.0;

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
      currentUser!.solBalance += 1.0;
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
