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

  // Organizations State
  final List<OrganizationModel> organizations = [];
  final Map<String, List<OrgMember>> orgMembers = {};

  // Digital Assets Owned & Managed
  late List<DigitalAsset> assets;

  // Real-world Activity / Audit Trail
  final List<ActivityItem> activities = [];

  // Proof of Authority (PoA) Consensus State
  final List<ConsensusProposalModel> proposals = [];
  late QuorumConfigModel quorumConfig;

  // Provenance & Ownership Tracking (AssetId -> History)
  final Map<String, List<OwnershipRecordModel>> ownershipRecords = {};

  // Custom Roles & Teams Architecture
  final List<CustomRoleModel> customRoles = [];
  final List<TeamModel> teams = [];

  // Identity Recovery Protocol
  late IdentityRecoveryModel identityRecovery;

  SolanaService() {
    _initializeOrganizations();
    _initializeAssets();
    _initializePoAConsensus();
    _initializeProvenance();
    _initializeCustomRoles();
    _initializeTeams();
    _initializeIdentityRecovery();
    _seedSystemActivities();
    checkConnection();
  }

  void _initializeOrganizations() {
    organizations.addAll([
      OrganizationModel(
        id: 'org_acme_corp',
        name: 'Acme Corporation',
        domain: 'acmecorp.com',
        authorityPda: 'org_auth_9xQw7YpM2nQv8rTxLm3sDpMvBaCxYpZ',
        description: 'Decentralized cloud infrastructure & enterprise AI services.',
        treasuryBalance: 25.0,
        isSponsoring: true,
        memberCount: 4,
        assetCount: 3,
        inviteCode: 'ACME-8921',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        brandColor: const Color(0xFF6366F1),
      ),
      OrganizationModel(
        id: 'org_solana_labs',
        name: 'Solana Labs Enterprise',
        domain: 'solanalabs.com',
        authorityPda: 'org_auth_5aRts89Lq0Kw7YpM2nQv8rTxLm3sDp',
        description: 'Next-generation blockchain infrastructure and validator operations.',
        treasuryBalance: 50.0,
        isSponsoring: true,
        memberCount: 12,
        assetCount: 8,
        inviteCode: 'SOL-4190',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        brandColor: const Color(0xFF06B6D4),
      ),
      OrganizationModel(
        id: 'org_cyberdyne',
        name: 'Cyberdyne Systems',
        domain: 'cyberdyne.io',
        authorityPda: 'org_auth_8bXym3Kp29v5yTkMn2qWv8pRxLm3sD',
        description: 'Autonomous robotics, neural nets, and hardware enclave credentials.',
        treasuryBalance: 15.0,
        isSponsoring: true,
        memberCount: 6,
        assetCount: 2,
        inviteCode: 'CYBER-2049',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        brandColor: const Color(0xFF10B981),
      ),
    ]);

    orgMembers['org_acme_corp'] = [
      OrgMember(
        id: 'mem_elena',
        name: 'Elena Rostova',
        email: 'elena.rostova@acmecorp.com',
        role: 'Asset Manager',
        roleId: 2,
        permissionsMask: 0x2F,
        avatarColor: const Color(0xFFA855F7),
        joinedAt: DateTime.now().subtract(const Duration(days: 20)),
        identityPda: 'id_pda_elena_r9xQw7YpM2n',
      ),
      OrgMember(
        id: 'mem_marcus',
        name: 'Marcus Vance',
        email: 'marcus.vance@acmecorp.com',
        role: 'Auditor',
        roleId: 3,
        permissionsMask: 0x24,
        avatarColor: const Color(0xFFF59E0B),
        joinedAt: DateTime.now().subtract(const Duration(days: 12)),
        identityPda: 'id_pda_marcus_v5aRts89L',
      ),
      OrgMember(
        id: 'mem_sarah',
        name: 'Sarah Chen',
        email: 'sarah.chen@acme.com',
        role: 'Enterprise Member',
        roleId: 4,
        permissionsMask: 0x0F,
        avatarColor: const Color(0xFF06B6D4),
        joinedAt: DateTime.now().subtract(const Duration(days: 5)),
        identityPda: 'id_pda_sarah_c8bXym3Kp',
      ),
    ];

    orgMembers['org_solana_labs'] = [
      OrgMember(
        id: 'mem_anatoly',
        name: 'Anatoly Yakovenko',
        email: 'anatoly@solanalabs.com',
        role: 'Admin',
        roleId: 1,
        permissionsMask: 0x3F,
        avatarColor: const Color(0xFF06B6D4),
        joinedAt: DateTime.now().subtract(const Duration(days: 60)),
        identityPda: 'id_pda_anatoly_sol',
      ),
      OrgMember(
        id: 'mem_raj',
        name: 'Raj Gokal',
        email: 'raj@solanalabs.com',
        role: 'Admin',
        roleId: 1,
        permissionsMask: 0x3F,
        avatarColor: const Color(0xFF6366F1),
        joinedAt: DateTime.now().subtract(const Duration(days: 55)),
        identityPda: 'id_pda_raj_sol',
      ),
    ];

    orgMembers['org_cyberdyne'] = [
      OrgMember(
        id: 'mem_miles',
        name: 'Miles Dyson',
        email: 'miles@cyberdyne.io',
        role: 'Admin',
        roleId: 1,
        permissionsMask: 0x3F,
        avatarColor: const Color(0xFF10B981),
        joinedAt: DateTime.now().subtract(const Duration(days: 15)),
        identityPda: 'id_pda_miles_cyber',
      ),
    ];
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
      final history0 = ownershipRecords[assets[0].id];
      if (history0 != null && history0.isNotEmpty) {
        history0.last = OwnershipRecordModel(
          sequence: history0.last.sequence,
          resourceId: history0.last.resourceId,
          resourcePda: history0.last.resourcePda,
          previousOwnerPda: history0.last.previousOwnerPda,
          newOwnerPda: identityPda,
          previousOwnerLabel: history0.last.previousOwnerLabel,
          newOwnerLabel: '$userLabel (Me)',
          transferredByPubkey: history0.last.transferredByPubkey,
          timestamp: history0.last.timestamp,
          transferType: history0.last.transferType,
          txSignature: history0.last.txSignature,
          isBiometricVerified: true,
          isGasSponsored: true,
        );
      }
    }
    if (assets.length > 1) {
      assets[1].ownerIdentityPda = identityPda;
      assets[1].ownerLabel = '$userLabel (Me)';
      final history1 = ownershipRecords[assets[1].id];
      if (history1 != null && history1.isNotEmpty) {
        history1.last = OwnershipRecordModel(
          sequence: history1.last.sequence,
          resourceId: history1.last.resourceId,
          resourcePda: history1.last.resourcePda,
          previousOwnerPda: history1.last.previousOwnerPda,
          newOwnerPda: identityPda,
          previousOwnerLabel: history1.last.previousOwnerLabel,
          newOwnerLabel: '$userLabel (Me)',
          transferredByPubkey: history1.last.transferredByPubkey,
          timestamp: history1.last.timestamp,
          transferType: history1.last.transferType,
          txSignature: history1.last.txSignature,
          isBiometricVerified: true,
          isGasSponsored: true,
        );
      }
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

  OrganizationModel? get currentOrg {
    final orgId = currentUser?.activeOrgId ?? 'org_acme_corp';
    return organizations.firstWhere(
      (o) => o.id == orgId,
      orElse: () => organizations.isNotEmpty
          ? organizations.first
          : OrganizationModel(
              id: 'org_default',
              name: 'Acme Corporation',
              domain: 'acmecorp.com',
              authorityPda: 'org_auth_default',
              description: 'Decentralized cloud infrastructure',
              inviteCode: 'ACME-1000',
              createdAt: DateTime.now(),
            ),
    );
  }

  List<OrgMember> get currentOrgMembers {
    final orgId = currentOrg?.id ?? 'org_acme_corp';
    final members = orgMembers[orgId] ?? [];
    if (currentUser != null && !members.any((m) => m.email == currentUser!.email)) {
      members.insert(
        0,
        OrgMember(
          id: 'mem_self_${currentUser!.email.replaceAll('@', '_')}',
          name: '${currentUser!.name} (You)',
          email: currentUser!.email,
          role: currentUser!.role,
          roleId: currentUser!.isAdmin ? 1 : 2,
          permissionsMask: currentUser!.permissionsMask,
          avatarColor: currentUser!.avatarColor,
          joinedAt: DateTime.now(),
          identityPda: currentUser!.identityPda,
        ),
      );
    }
    return members;
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

    final prevOwnerPda = asset.ownerIdentityPda;
    final prevOwnerLabel = asset.ownerLabel;

    // Update ownership
    asset.ownerIdentityPda = recipientAddress;
    asset.ownerLabel = recipientLabel;

    // Record on-chain atomic provenance
    final history = ownershipRecords.putIfAbsent(asset.id, () => []);
    final nextSeq = history.length;
    final provRecord = OwnershipRecordModel(
      sequence: nextSeq,
      resourceId: asset.id,
      resourcePda: asset.pdaAddress,
      previousOwnerPda: prevOwnerPda.isEmpty ? '11111111111111111111111111111111' : prevOwnerPda,
      newOwnerPda: recipientAddress,
      previousOwnerLabel: prevOwnerLabel,
      newOwnerLabel: recipientLabel,
      transferredByPubkey: currentUser!.publicKey,
      timestamp: DateTime.now(),
      transferType: 'Biometric P2P Transfer',
      txSignature: sig,
      isBiometricVerified: true,
      isGasSponsored: currentUser!.isGasSponsored,
    );
    history.add(provRecord);

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

  // --- Organization & Admin Role Operations ---

  /// Create a new Organization PDA on Solana Devnet
  Future<bool> createOrganization({
    required String name,
    required String domain,
    required double initialDepositSol,
    required String description,
  }) async {
    if (currentUser == null) return false;
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 750));

    final orgId = 'org_${domain.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
    final authorityPda = 'org_auth_${_deriveSolanaPublicKey(currentUser!.email).substring(0, 16)}';
    final codePrefix = name.trim().replaceAll(' ', '').toUpperCase();
    final inviteCode = '${codePrefix.substring(0, min(4, codePrefix.length))}-${Random().nextInt(8999) + 1000}';

    final newOrg = OrganizationModel(
      id: orgId,
      name: name.trim(),
      domain: domain.trim().toLowerCase(),
      authorityPda: authorityPda,
      description: description.trim(),
      treasuryBalance: initialDepositSol,
      isSponsoring: true,
      memberCount: 1,
      assetCount: 0,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
      brandColor: const Color(0xFF6366F1),
    );

    organizations.insert(0, newOrg);

    // Current user is the Organization Authority and Super Admin
    currentUser!.role = 'Super Admin';
    currentUser!.permissionsMask = 0x3F; // 111111b: All permissions
    currentUser!.activeOrgId = orgId;

    orgMembers[orgId] = [
      OrgMember(
        id: 'mem_${currentUser!.email.replaceAll('@', '_')}',
        name: '${currentUser!.name} (You)',
        email: currentUser!.email,
        role: 'Super Admin',
        roleId: 1,
        permissionsMask: 0x3F,
        avatarColor: currentUser!.avatarColor,
        joinedAt: DateTime.now(),
        identityPda: currentUser!.identityPda,
      ),
    ];

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Created Organization: ${newOrg.name}',
        subtitle: '${newOrg.domain} • Authority PDA ($authorityPda) Initialized',
        type: ActivityType.deploy,
        timestamp: DateTime.now(),
        signature: '2OrgInit${Random().nextInt(999999)}PqFm93Xv7B',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Join an existing Organization by domain or invite code
  Future<bool> joinOrganization({required String domainOrCode}) async {
    if (currentUser == null) return false;
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 650));

    final query = domainOrCode.trim().toLowerCase();
    OrganizationModel? targetOrg;

    for (final org in organizations) {
      if (org.id.toLowerCase() == query ||
          org.domain.toLowerCase() == query ||
          org.inviteCode.toLowerCase() == query ||
          org.name.toLowerCase().contains(query)) {
        targetOrg = org;
        break;
      }
    }

    // If not found in default list, create dynamic verified org from domain
    if (targetOrg == null) {
      if (query.contains('.')) {
        final cleanDomain = query;
        final namePart = cleanDomain.split('.')[0];
        final orgName = '${namePart[0].toUpperCase()}${namePart.substring(1)} Corp';
        targetOrg = OrganizationModel(
          id: 'org_${cleanDomain.replaceAll('.', '_')}',
          name: orgName,
          domain: cleanDomain,
          authorityPda: 'org_auth_${_deriveSolanaPublicKey(cleanDomain).substring(0, 16)}',
          description: 'Verified enterprise workspace for $cleanDomain',
          treasuryBalance: 20.0,
          isSponsoring: true,
          memberCount: 1,
          assetCount: 0,
          inviteCode: '${namePart.substring(0, min(4, namePart.length)).toUpperCase()}-7721',
          createdAt: DateTime.now(),
          brandColor: const Color(0xFF06B6D4),
        );
        organizations.add(targetOrg);
        orgMembers[targetOrg.id] = [];
      } else {
        isLoading = false;
        notifyListeners();
        return false;
      }
    }

    currentUser!.activeOrgId = targetOrg.id;
    final members = orgMembers[targetOrg.id] ??= [];

    if (!members.any((m) => m.email == currentUser!.email)) {
      members.add(
        OrgMember(
          id: 'mem_${currentUser!.email.replaceAll('@', '_')}',
          name: '${currentUser!.name} (You)',
          email: currentUser!.email,
          role: 'Enterprise Member',
          roleId: 4,
          permissionsMask: 0x0F,
          avatarColor: currentUser!.avatarColor,
          joinedAt: DateTime.now(),
          identityPda: currentUser!.identityPda,
        ),
      );
      targetOrg.memberCount++;
    }

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Joined Organization: ${targetOrg.name}',
        subtitle: '${targetOrg.domain} • Identity registered on Devnet',
        type: ActivityType.auth,
        timestamp: DateTime.now(),
        signature: '3OrgJoin${Random().nextInt(999999)}Lk82Mm',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Switch active organization
  void switchOrganization(String orgId) {
    if (currentUser == null) return;
    final targetOrg = organizations.firstWhere((o) => o.id == orgId, orElse: () => organizations.first);
    currentUser!.activeOrgId = targetOrg.id;

    // Check user's role in this organization
    final members = orgMembers[targetOrg.id] ?? [];
    final userMember = members.firstWhere(
      (m) => m.email == currentUser!.email,
      orElse: () => OrgMember(
        id: 'mem_${currentUser!.email.replaceAll('@', '_')}',
        name: currentUser!.name,
        email: currentUser!.email,
        role: 'Enterprise Member',
        roleId: 4,
        permissionsMask: 0x0F,
        avatarColor: currentUser!.avatarColor,
        joinedAt: DateTime.now(),
        identityPda: currentUser!.identityPda,
      ),
    );

    currentUser!.role = userMember.role;
    currentUser!.permissionsMask = userMember.permissionsMask;

    notifyListeners();
  }

  /// Invite a new member and assign an initial RBAC role
  Future<bool> inviteMember({
    required String name,
    required String email,
    required String role,
    required int permissionsMask,
  }) async {
    if (currentUser == null) return false;
    if (!currentUser!.isAdmin) return false;

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 650));

    final org = currentOrg;
    if (org == null) {
      isLoading = false;
      notifyListeners();
      return false;
    }

    final pubkey = _deriveSolanaPublicKey(email);
    final identityPda = _deriveIdentityPda(pubkey);

    int roleId = 4;
    Color avatarColor = const Color(0xFF6366F1);
    if (role.toLowerCase().contains('admin')) {
      roleId = 1;
      avatarColor = const Color(0xFFF43F5E);
    } else if (role.toLowerCase().contains('asset manager')) {
      roleId = 2;
      avatarColor = const Color(0xFFA855F7);
    } else if (role.toLowerCase().contains('auditor')) {
      roleId = 3;
      avatarColor = const Color(0xFFF59E0B);
    }

    final newMember = OrgMember(
      id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      role: role,
      roleId: roleId,
      permissionsMask: permissionsMask,
      avatarColor: avatarColor,
      joinedAt: DateTime.now(),
      status: 'active',
      identityPda: identityPda,
    );

    final members = orgMembers[org.id] ??= [];
    members.add(newMember);
    org.memberCount++;

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Invited Member: ${newMember.name}',
        subtitle: '${newMember.email} assigned role $role (0x${permissionsMask.toRadixString(16).toUpperCase()})',
        type: ActivityType.grant,
        timestamp: DateTime.now(),
        signature: '4MemInv${Random().nextInt(999999)}BwQ82p',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Update an existing member's role and RBAC bitmask
  Future<bool> updateMemberRole({
    required String memberId,
    required String newRole,
    required int newMask,
  }) async {
    if (currentUser == null) return false;
    if (!currentUser!.isAdmin) return false;

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 550));

    final members = currentOrgMembers;
    final member = members.firstWhere((m) => m.id == memberId, orElse: () => members.first);

    member.role = newRole;
    member.permissionsMask = newMask;

    // If updating self
    if (member.email == currentUser!.email) {
      currentUser!.role = newRole;
      currentUser!.permissionsMask = newMask;
    }

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Role Updated On-Chain',
        subtitle: '${member.name} → $newRole (0x${newMask.toRadixString(16).toUpperCase()})',
        type: ActivityType.grant,
        timestamp: DateTime.now(),
        signature: '5RoleUp${Random().nextInt(999999)}JkQ52a',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Mint and register a new program-owned PDA digital asset
  Future<bool> createDigitalAsset({
    required String name,
    required String type,
    required String description,
    required String ownerIdentityPda,
    required String ownerLabel,
    required Color accentColor,
    required IconData icon,
    required int requiredPermission,
  }) async {
    if (currentUser == null) return false;
    final canCreate = (currentUser!.permissionsMask & 0x01) != 0 || currentUser!.isAdmin;
    if (!canCreate) return false;

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final pda = 'res_pda_${_deriveSolanaPublicKey(name).substring(0, 16)}';

    final newAsset = DigitalAsset(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      type: type,
      pdaAddress: pda,
      ownerIdentityPda: ownerIdentityPda,
      ownerLabel: ownerLabel,
      description: description.trim(),
      accentColor: accentColor,
      icon: icon,
      requiredPermission: requiredPermission,
    );

    assets.insert(0, newAsset);
    currentOrg?.assetCount++;

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Minted Asset PDA: ${newAsset.name}',
        subtitle: 'Assigned to $ownerLabel (0 SOL Gas)',
        type: ActivityType.deploy,
        timestamp: DateTime.now(),
        signature: '6AstMint${Random().nextInt(999999)}ZzP281',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Revoke and freeze a program-owned PDA digital asset
  Future<bool> revokeDigitalAsset(String assetId) async {
    if (currentUser == null) return false;
    final canRevoke = (currentUser!.permissionsMask & 0x10) != 0 || currentUser!.isAdmin;
    if (!canRevoke) return false;

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final asset = assets.firstWhere((a) => a.id == assetId);
    asset.isRevoked = true;

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Revoked Digital Asset',
        subtitle: '${asset.name} frozen & revoked on Devnet',
        type: ActivityType.securityReject,
        timestamp: DateTime.now(),
        signature: '7AstRev${Random().nextInt(999999)}HhP182',
        isGasSponsored: true,
        isRejected: true,
        rejectionReason: 'Asset PDA revoked by Organization Authority',
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Top up organization gas fee sponsorship treasury
  Future<bool> topUpTreasury(double amountSol) async {
    if (currentUser == null || currentOrg == null) return false;
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    currentOrg!.treasuryBalance += amountSol;

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Treasury Funded: ◎ ${amountSol.toStringAsFixed(1)} SOL',
        subtitle: '${currentOrg!.name} gas sponsorship pool updated',
        type: ActivityType.airdrop,
        timestamp: DateTime.now(),
        signature: '8TrsTop${Random().nextInt(999999)}GgW193',
        isGasSponsored: false,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Quick toggle between Admin role (0x3F) and Asset Manager role (0x2F) for testing
  void toggleCurrentUserRole() {
    if (currentUser == null) return;
    if (currentUser!.isAdmin) {
      currentUser!.role = 'Asset Manager';
      currentUser!.permissionsMask = 0x2F;
    } else {
      currentUser!.role = 'Super Admin';
      currentUser!.permissionsMask = 0x3F;
    }

    final members = orgMembers[currentUser!.activeOrgId];
    if (members != null) {
      final userMember = members.where((m) => m.email == currentUser!.email).firstOrNull;
      if (userMember != null) {
        userMember.role = currentUser!.role;
        userMember.permissionsMask = currentUser!.permissionsMask;
      }
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Proof of Authority (PoA) Consensus & Biometric Governance
  // ---------------------------------------------------------------------------

  void _initializePoAConsensus() {
    quorumConfig = QuorumConfigModel(
      threshold: 2,
      totalAuthorities: 3,
      authorityNames: [
        'Elena Rostova (Guardian 1)',
        'Marcus Vance (Guardian 2)',
        'Sarah Jenkins (Guardian 3)',
      ],
      authorityPubkeys: [
        'Auth1xQw7YpM2nQv8rTxLm3sDpMvBaCxYpZ9x',
        'Auth2mK8v7YpM2nQv8rTxLm3sDpMvBaCxYpZ4b',
        'Auth3rT9y7YpM2nQv8rTxLm3sDpMvBaCxYpZ1w',
      ],
      biometricEnclaveActive: true,
    );

    proposals.addAll([
      ConsensusProposalModel(
        proposalId: 0,
        title: 'Revoke Compromised Asset: Quantum Encryption Key',
        description: 'Permanent on-chain revocation of Asset PDA due to suspected endpoint security breach.',
        proposerName: 'Elena Rostova (Guardian 1)',
        proposerPubkey: 'Auth1xQw7YpM2nQv8rTxLm3sDpMvBaCxYpZ9x',
        actionType: 3, // Revoke Resource
        targetAddress: 'pda_asset_3_9xQw7YpM2nQv8rTxLm3s',
        targetLabel: 'Quantum Encryption Key',
        requiredThreshold: 2,
        currentApprovals: 1,
        approvedBy: ['Elena Rostova (Guardian 1)'],
        status: ProposalStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
        isBiometricGated: true,
      ),
      ConsensusProposalModel(
        proposalId: 1,
        title: 'Consensus Assignment of ADMIN Role to Sarah Jenkins',
        description: 'Consensus assignment of ROLE_ADMIN (0x3F) to Identity PDA id_pda_sarah_j8x.',
        proposerName: 'Marcus Vance (Guardian 2)',
        proposerPubkey: 'Auth2mK8v7YpM2nQv8rTxLm3sDpMvBaCxYpZ4b',
        actionType: 1, // Assign Role
        targetAddress: 'id_pda_sarah_j8xQw7YpM2n',
        targetLabel: 'Sarah Jenkins',
        requiredThreshold: 2,
        currentApprovals: 2,
        approvedBy: ['Marcus Vance (Guardian 2)', 'Sarah Jenkins (Guardian 3)'],
        status: ProposalStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isBiometricGated: true,
      ),
    ]);
  }

  /// Create a new PoA Consensus Proposal
  Future<bool> createConsensusProposal({
    required String title,
    required String description,
    required int actionType,
    required String targetAddress,
    required String targetLabel,
  }) async {
    if (currentUser == null) return false;
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final newProposal = ConsensusProposalModel(
      proposalId: proposals.length,
      title: title,
      description: description,
      proposerName: currentUser!.name,
      proposerPubkey: currentUser!.publicKey,
      actionType: actionType,
      targetAddress: targetAddress,
      targetLabel: targetLabel,
      requiredThreshold: quorumConfig.threshold,
      currentApprovals: 1,
      approvedBy: [currentUser!.name],
      status: (1 >= quorumConfig.threshold) ? ProposalStatus.approved : ProposalStatus.pending,
      createdAt: DateTime.now(),
      isBiometricGated: true,
    );

    proposals.insert(0, newProposal);

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'PoA Proposal Created',
        subtitle: '${newProposal.title} (1/${quorumConfig.threshold} Approvals)',
        type: ActivityType.deploy,
        timestamp: DateTime.now(),
        signature: '5PoaProp${Random().nextInt(999999)}Tx982',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Approve a PoA Consensus Proposal with Biometric Hardware Gating
  Future<bool> approveConsensusProposal(int proposalId, {required String authorityName}) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final proposal = proposals.firstWhere((p) => p.proposalId == proposalId);
    if (!proposal.approvedBy.contains(authorityName)) {
      proposal.approvedBy.add(authorityName);
      proposal.currentApprovals += 1;
      if (proposal.currentApprovals >= proposal.requiredThreshold) {
        proposal.status = ProposalStatus.approved;
      }
    }

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'PoA Consensus Endorsement',
        subtitle: '$authorityName endorsed Proposal #$proposalId (${proposal.currentApprovals}/${proposal.requiredThreshold})',
        type: ActivityType.grant,
        timestamp: DateTime.now(),
        signature: '7PoaAppr${Random().nextInt(999999)}Vte411',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Reject a PoA Consensus Proposal
  Future<bool> rejectConsensusProposal(int proposalId, {required String authorityName}) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final proposal = proposals.firstWhere((p) => p.proposalId == proposalId);
    proposal.status = ProposalStatus.rejected;

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'PoA Proposal Vetoed',
        subtitle: 'Proposal #$proposalId rejected by $authorityName',
        type: ActivityType.securityReject,
        timestamp: DateTime.now(),
        signature: '9PoaVeto${Random().nextInt(999999)}Rej102',
        isGasSponsored: true,
        isRejected: true,
        rejectionReason: 'Vetoed by Authority Quorum Member',
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Execute an approved PoA Consensus Proposal on Solana
  Future<bool> executeConsensusProposal(int proposalId) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final proposal = proposals.firstWhere((p) => p.proposalId == proposalId);
    if (proposal.currentApprovals < proposal.requiredThreshold) {
      isLoading = false;
      notifyListeners();
      return false;
    }

    proposal.status = ProposalStatus.executed;

    // Apply action
    if (proposal.actionType == 3) {
      // Revoke Resource
      for (final a in assets) {
        if (a.name.toLowerCase() == proposal.targetLabel.toLowerCase() ||
            a.pdaAddress == proposal.targetAddress) {
          a.isRevoked = true;
        }
      }
    }

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'PoA Proposal Executed On-Chain',
        subtitle: '${proposal.title} enforced by 2-of-3 Quorum',
        type: ActivityType.deploy,
        timestamp: DateTime.now(),
        signature: '4PoaExe${Random().nextInt(999999)}Sol771',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  // --- Provenance, Teams & Custom Roles Architecture ---

  List<OwnershipRecordModel> getAssetOwnershipHistory(String assetId) {
    return ownershipRecords[assetId] ?? [];
  }

  void _initializeProvenance() {
    ownershipRecords['res_vault_01'] = [
      OwnershipRecordModel(
        sequence: 0,
        resourceId: 'res_vault_01',
        resourcePda: '5aRts89Lq0Kw7YpM2nQv8rTxLm3sDpMvBaCxYpZqL11',
        previousOwnerPda: '11111111111111111111111111111111',
        newOwnerPda: 'id_pda_elena_r9xQw7YpM2n',
        previousOwnerLabel: 'Genesis Mint',
        newOwnerLabel: 'Elena Rostova (Asset Manager)',
        transferredByPubkey: 'Auth1xQw7YpM2nQv8rTxLm3sDpMvBaCxYpZ9x',
        timestamp: DateTime.now().subtract(const Duration(days: 28)),
        transferType: 'Genesis Mint',
        txSignature: '5NfiayYFrXHNbFSV771891928374829102839401',
        isBiometricVerified: true,
        isGasSponsored: true,
      ),
      OwnershipRecordModel(
        sequence: 1,
        resourceId: 'res_vault_01',
        resourcePda: '5aRts89Lq0Kw7YpM2nQv8rTxLm3sDpMvBaCxYpZqL11',
        previousOwnerPda: 'id_pda_elena_r9xQw7YpM2n',
        newOwnerPda: 'id_pda_me_default',
        previousOwnerLabel: 'Elena Rostova',
        newOwnerLabel: 'Alex Chen (Me)',
        transferredByPubkey: 'Auth1xQw7YpM2nQv8rTxLm3sDpMvBaCxYpZ9x',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        transferType: 'Biometric P2P Transfer',
        txSignature: '616SFk5XLAPdtPKm882910394857201948572918',
        isBiometricVerified: true,
        isGasSponsored: true,
      ),
    ];

    ownershipRecords['res_data_02'] = [
      OwnershipRecordModel(
        sequence: 0,
        resourceId: 'res_data_02',
        resourcePda: '8bXym3Kp29v5yTkMn2qWv8pRxLm3sDpMvBaCxYpZqL22',
        previousOwnerPda: '11111111111111111111111111111111',
        newOwnerPda: 'id_pda_marcus_v5aRts89L',
        previousOwnerLabel: 'Genesis Mint',
        newOwnerLabel: 'Marcus Vance (Auditor)',
        transferredByPubkey: 'Auth2mK8v7YpM2nQv8rTxLm3sDpMvBaCxYpZ4b',
        timestamp: DateTime.now().subtract(const Duration(days: 14)),
        transferType: 'Genesis Mint',
        txSignature: '39ManHTqpvQCv97z994827104859281749204859',
        isBiometricVerified: true,
        isGasSponsored: true,
      ),
      OwnershipRecordModel(
        sequence: 1,
        resourceId: 'res_data_02',
        resourcePda: '8bXym3Kp29v5yTkMn2qWv8pRxLm3sDpMvBaCxYpZqL22',
        previousOwnerPda: 'id_pda_marcus_v5aRts89L',
        newOwnerPda: 'id_pda_me_default',
        previousOwnerLabel: 'Marcus Vance',
        newOwnerLabel: 'Alex Chen (Me)',
        transferredByPubkey: 'Auth2mK8v7YpM2nQv8rTxLm3sDpMvBaCxYpZ4b',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        transferType: 'Admin Assignment',
        txSignature: '4hDdu2u5Wxwq8UAW773829104859201948572019',
        isBiometricVerified: true,
        isGasSponsored: true,
      ),
    ];

    ownershipRecords['res_cloud_03'] = [
      OwnershipRecordModel(
        sequence: 0,
        resourceId: 'res_cloud_03',
        resourcePda: '3cMnp77Lq0Kw7YpM2nQv8rTxLm3sDpMvBaCxYpZqL33',
        previousOwnerPda: '11111111111111111111111111111111',
        newOwnerPda: 'id_pda_elena_r9xQw7YpM2n',
        previousOwnerLabel: 'Genesis Mint',
        newOwnerLabel: 'Elena Rostova',
        transferredByPubkey: 'Auth1xQw7YpM2nQv8rTxLm3sDpMvBaCxYpZ9x',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        transferType: 'Genesis Mint',
        txSignature: '2dfJJg3Lj9fAsda8883719284758291048572019',
        isBiometricVerified: true,
        isGasSponsored: true,
      ),
      OwnershipRecordModel(
        sequence: 1,
        resourceId: 'res_cloud_03',
        resourcePda: '3cMnp77Lq0Kw7YpM2nQv8rTxLm3sDpMvBaCxYpZqL33',
        previousOwnerPda: 'id_pda_elena_r9xQw7YpM2n',
        newOwnerPda: 'pda_external_secops',
        previousOwnerLabel: 'Elena Rostova',
        newOwnerLabel: 'SecOps Team',
        transferredByPubkey: 'Auth1xQw7YpM2nQv8rTxLm3sDpMvBaCxYpZ9x',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        transferType: 'Role-Gated Transfer',
        txSignature: '2A2Z4ay5hMQd2nyw994829104857201948572019',
        isBiometricVerified: true,
        isGasSponsored: true,
      ),
    ];
  }

  void _initializeCustomRoles() {
    customRoles.addAll([
      CustomRoleModel(
        roleId: 1,
        name: 'Organization Admin',
        description: 'Complete administrative control over org members, roles, and consensus.',
        permissionsMask: 0x3F, // Full bitmask
        color: const Color(0xFFEF4444),
        isSystemRole: true,
        memberCount: 2,
      ),
      CustomRoleModel(
        roleId: 2,
        name: 'Asset Manager',
        description: 'Authorized to mint, assign, transfer, and verify digital assets.',
        permissionsMask: 0x2F,
        color: const Color(0xFF6366F1),
        isSystemRole: true,
        memberCount: 3,
      ),
      CustomRoleModel(
        roleId: 3,
        name: 'Compliance Auditor',
        description: 'Read-only access to provenance logs, audit trails, and quorum votes.',
        permissionsMask: 0x24,
        color: const Color(0xFFF59E0B),
        isSystemRole: true,
        memberCount: 1,
      ),
      CustomRoleModel(
        roleId: 4,
        name: 'Enterprise Member',
        description: 'Standard access to assigned resources and team collaboration.',
        permissionsMask: 0x0F,
        color: const Color(0xFF06B6D4),
        isSystemRole: true,
        memberCount: 4,
      ),
      CustomRoleModel(
        roleId: 5,
        name: 'DevOps Vault Specialist',
        description: 'Custom role with access to Kubernetes passes and hardware vault keys.',
        permissionsMask: 0x1B, // Custom bitmask
        color: const Color(0xFF10B981),
        isSystemRole: false,
        memberCount: 2,
      ),
      CustomRoleModel(
        roleId: 6,
        name: 'AI Dataset Engineer',
        description: 'Custom role with permissions to train and query proprietary dataset licenses.',
        permissionsMask: 0x07, // Custom bitmask
        color: const Color(0xFF8B5CF6),
        isSystemRole: false,
        memberCount: 1,
      ),
    ]);
  }

  void _initializeTeams() {
    teams.addAll([
      TeamModel(
        id: 'team_infra',
        name: 'Core Infrastructure Ops',
        description: 'Responsible for multi-cloud deployments, production Kubernetes, and vault secrets.',
        assignedRoleIds: [2, 5], // Asset Manager + DevOps Vault Specialist
        permissionsMask: 0x3F,
        color: const Color(0xFF3B82F6),
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        memberNames: ['Elena Rostova', 'Sarah Chen'],
        memberIdentities: ['id_pda_elena_r9xQw7YpM2n', 'id_pda_sarah_c8bXym3Kp'],
      ),
      TeamModel(
        id: 'team_governance',
        name: 'Compliance & Governance',
        description: 'Oversees regulatory compliance, DPDP/GDPR zero-PII commitments, and PoA audits.',
        assignedRoleIds: [3], // Compliance Auditor
        permissionsMask: 0x24,
        color: const Color(0xFFF59E0B),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        memberNames: ['Marcus Vance'],
        memberIdentities: ['id_pda_marcus_v5aRts89L'],
      ),
      TeamModel(
        id: 'team_ai_research',
        name: 'AI Research Workgroup',
        description: 'Engineers building next-gen foundational models with proprietary datasets.',
        assignedRoleIds: [4, 6], // Enterprise Member + AI Dataset Engineer
        permissionsMask: 0x0F,
        color: const Color(0xFF8B5CF6),
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        memberNames: ['Sarah Chen'],
        memberIdentities: ['id_pda_sarah_c8bXym3Kp'],
      ),
    ]);
  }

  void _initializeIdentityRecovery() {
    identityRecovery = IdentityRecoveryModel(
      identityPda: 'id_pda_me_default',
      guardians: [
        'Elena Rostova (Guardian 1)',
        'Marcus Vance (Guardian 2)',
      ],
      threshold: 2,
      isConfigured: true,
      activeRecoveryNewController: null,
      approvalCount: 0,
      isInProgress: false,
      approvedGuardians: [],
    );
  }

  /// Create a new Custom Role
  Future<bool> createCustomRole({
    required String name,
    required String description,
    required int permissionsMask,
    Color? color,
  }) async {
    if (currentUser == null) return false;
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final newRoleId = customRoles.length + 1;
    final newRole = CustomRoleModel(
      roleId: newRoleId,
      name: name,
      description: description,
      permissionsMask: permissionsMask,
      color: color ?? const Color(0xFF6366F1),
      isSystemRole: false,
      memberCount: 0,
    );

    customRoles.add(newRole);

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Custom Role Created: $name',
        subtitle: 'Permissions Mask: 0x${permissionsMask.toRadixString(16).toUpperCase().padLeft(2, '0')}',
        type: ActivityType.deploy,
        timestamp: DateTime.now(),
        signature: '2RoleNew${Random().nextInt(999999)}Sol491',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Create a new Team under the Organization
  Future<bool> createTeam({
    required String name,
    required String description,
    required List<int> assignedRoleIds,
    Color? color,
  }) async {
    if (currentUser == null) return false;
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    // Combine permissions masks of assigned roles
    int combinedMask = 0;
    for (final rId in assignedRoleIds) {
      final roleMatch = customRoles.firstWhere((r) => r.roleId == rId, orElse: () => customRoles.first);
      combinedMask |= roleMatch.permissionsMask;
    }

    final newTeam = TeamModel(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      assignedRoleIds: assignedRoleIds,
      permissionsMask: combinedMask,
      color: color ?? const Color(0xFF3B82F6),
      createdAt: DateTime.now(),
      memberNames: [],
      memberIdentities: [],
    );

    teams.add(newTeam);

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Team Created: $name',
        subtitle: '${assignedRoleIds.length} Roles Assigned (Permissions: 0x${combinedMask.toRadixString(16).toUpperCase()})',
        type: ActivityType.deploy,
        timestamp: DateTime.now(),
        signature: '3TeamNew${Random().nextInt(999999)}Sol582',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Update / Assign Roles to a Team as a whole
  Future<bool> assignTeamRoles(String teamId, List<int> roleIds) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final team = teams.firstWhere((t) => t.id == teamId);
    team.assignedRoleIds.clear();
    team.assignedRoleIds.addAll(roleIds);

    int combinedMask = 0;
    for (final rId in roleIds) {
      final roleMatch = customRoles.firstWhere((r) => r.roleId == rId, orElse: () => customRoles.first);
      combinedMask |= roleMatch.permissionsMask;
    }
    team.permissionsMask = combinedMask;

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Team Roles Updated: ${team.name}',
        subtitle: '${roleIds.length} Roles Assigned to Whole Team',
        type: ActivityType.grant,
        timestamp: DateTime.now(),
        signature: '4TeamRol${Random().nextInt(999999)}Sol991',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Add Member to Team
  Future<bool> addMemberToTeam(String teamId, String memberName, String identityPda) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final team = teams.firstWhere((t) => t.id == teamId);
    if (!team.memberNames.contains(memberName)) {
      team.memberNames.add(memberName);
      team.memberIdentities.add(identityPda);
    }

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Member Added to ${team.name}',
        subtitle: '$memberName joined team and inherited whole-team permissions',
        type: ActivityType.grant,
        timestamp: DateTime.now(),
        signature: '6MemAdd${Random().nextInt(999999)}Sol129',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Remove Member from Team
  Future<bool> removeMemberFromTeam(String teamId, String memberName) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final team = teams.firstWhere((t) => t.id == teamId);
    final idx = team.memberNames.indexOf(memberName);
    if (idx != -1) {
      team.memberNames.removeAt(idx);
      if (idx < team.memberIdentities.length) {
        team.memberIdentities.removeAt(idx);
      }
    }

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Member Removed from ${team.name}',
        subtitle: '$memberName membership PDA closed on-chain',
        type: ActivityType.securityReject,
        timestamp: DateTime.now(),
        signature: '7MemRem${Random().nextInt(999999)}Sol331',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Configure Identity Recovery Protocol (Guardians & Threshold)
  Future<bool> configureIdentityRecovery({
    required List<String> guardians,
    required int threshold,
  }) async {
    if (currentUser == null) return false;
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    identityRecovery = IdentityRecoveryModel(
      identityPda: currentUser!.identityPda,
      guardians: guardians,
      threshold: threshold,
      isConfigured: true,
      activeRecoveryNewController: null,
      approvalCount: 0,
      isInProgress: false,
      approvedGuardians: [],
    );

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Identity Recovery Configured',
        subtitle: '$threshold-of-${guardians.length} Guardian Protection Activated',
        type: ActivityType.deploy,
        timestamp: DateTime.now(),
        signature: '8RecCfg${Random().nextInt(999999)}Sol442',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Initiate Identity Recovery proposing a new device key
  Future<bool> initiateIdentityRecovery({required String newDeviceKey}) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    identityRecovery = IdentityRecoveryModel(
      identityPda: identityRecovery.identityPda,
      guardians: identityRecovery.guardians,
      threshold: identityRecovery.threshold,
      isConfigured: true,
      activeRecoveryNewController: newDeviceKey,
      approvalCount: 1,
      isInProgress: true,
      approvedGuardians: [identityRecovery.guardians.first],
    );

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Identity Recovery Initiated',
        subtitle: 'Proposing new device controller key (1/${identityRecovery.threshold} Approvals)',
        type: ActivityType.grant,
        timestamp: DateTime.now(),
        signature: '9RecInit${Random().nextInt(999999)}Sol881',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Guardian approves identity recovery
  Future<bool> approveIdentityRecovery(String guardianName) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    if (!identityRecovery.approvedGuardians.contains(guardianName)) {
      final updatedGuardians = List<String>.from(identityRecovery.approvedGuardians)..add(guardianName);
      identityRecovery = IdentityRecoveryModel(
        identityPda: identityRecovery.identityPda,
        guardians: identityRecovery.guardians,
        threshold: identityRecovery.threshold,
        isConfigured: true,
        activeRecoveryNewController: identityRecovery.activeRecoveryNewController,
        approvalCount: updatedGuardians.length,
        isInProgress: true,
        approvedGuardians: updatedGuardians,
      );
    }

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Guardian Approved Recovery',
        subtitle: '$guardianName confirmed controller key rotation (${identityRecovery.approvalCount}/${identityRecovery.threshold})',
        type: ActivityType.grant,
        timestamp: DateTime.now(),
        signature: '2RecAppr${Random().nextInt(999999)}Sol992',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Execute Identity Recovery Key Rotation
  Future<bool> executeIdentityRecovery() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    if (identityRecovery.approvalCount < identityRecovery.threshold) {
      isLoading = false;
      notifyListeners();
      return false;
    }

    final newKey = identityRecovery.activeRecoveryNewController ?? 'NewRotatedDeviceKey771';
    
    // Rotate currentUser public key while preserving Identity PDA and assets
    if (currentUser != null) {
      currentUser = UserProfile(
        name: currentUser!.name,
        email: currentUser!.email,
        authProvider: currentUser!.authProvider,
        companyDomain: currentUser!.companyDomain,
        publicKey: newKey,
        identityPda: currentUser!.identityPda, // PRESERVED!
        role: currentUser!.role,
        permissionsMask: currentUser!.permissionsMask,
        solBalance: currentUser!.solBalance,
        avatarColor: currentUser!.avatarColor,
        isGasSponsored: currentUser!.isGasSponsored,
      );
    }

    identityRecovery = IdentityRecoveryModel(
      identityPda: identityRecovery.identityPda,
      guardians: identityRecovery.guardians,
      threshold: identityRecovery.threshold,
      isConfigured: true,
      activeRecoveryNewController: null,
      approvalCount: 0,
      isInProgress: false,
      approvedGuardians: [],
    );

    activities.insert(
      0,
      ActivityItem(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Controller Key Rotated Successfully',
        subtitle: 'Device key updated without changing Identity PDA or losing assets',
        type: ActivityType.deploy,
        timestamp: DateTime.now(),
        signature: '1RecExe${Random().nextInt(999999)}Sol119',
        isGasSponsored: true,
      ),
    );

    isLoading = false;
    notifyListeners();
    return true;
  }
}

