import 'package:flutter/material.dart';

enum AuthProvider { google, workEmail }

/// Represents the authenticated real-world user profile
class UserProfile {
  final String name;
  final String email;
  final AuthProvider authProvider;
  final String companyDomain;
  final String publicKey;
  final String identityPda;
  String role;
  int permissionsMask;
  double solBalance;
  final Color avatarColor;
  final bool isGasSponsored;
  String activeOrgId;

  UserProfile({
    required this.name,
    required this.email,
    required this.authProvider,
    required this.companyDomain,
    required this.publicKey,
    required this.identityPda,
    required this.role,
    required this.permissionsMask,
    this.solBalance = 0.0,
    required this.avatarColor,
    this.isGasSponsored = true,
    this.activeOrgId = 'org_acme_corp',
  });

  bool get isAdmin => (permissionsMask & 0x20) != 0 || role.toLowerCase().contains('admin');

  String get shortPublicKey {
    if (publicKey.length <= 10) return publicKey;
    return '${publicKey.substring(0, 4)}...${publicKey.substring(publicKey.length - 4)}';
  }

  String get shortIdentityPda {
    if (identityPda.length <= 10) return identityPda;
    return '${identityPda.substring(0, 4)}...${identityPda.substring(identityPda.length - 4)}';
  }

  String get providerDisplayName {
    switch (authProvider) {
      case AuthProvider.google:
        return 'Google OAuth';
      case AuthProvider.workEmail:
        return 'Work Email SSO ($companyDomain)';
    }
  }
}

/// Represents a program-owned PDA digital asset (Non-NFT, native PDA)
class DigitalAsset {
  final String id;
  final String name;
  final String type;
  final String pdaAddress;
  String ownerIdentityPda;
  String ownerLabel;
  final String description;
  final Color accentColor;
  final IconData icon;
  final int requiredPermission;
  bool isRevoked;

  DigitalAsset({
    required this.id,
    required this.name,
    required this.type,
    required this.pdaAddress,
    required this.ownerIdentityPda,
    required this.ownerLabel,
    required this.description,
    required this.accentColor,
    required this.icon,
    this.requiredPermission = 0x08, // TRANSFER_RESOURCE
    this.isRevoked = false,
  });

  String get shortPda {
    if (pdaAddress.length <= 10) return pdaAddress;
    return '${pdaAddress.substring(0, 4)}...${pdaAddress.substring(pdaAddress.length - 4)}';
  }
}

/// Human-readable transaction activity item (Wise & Phantom style)
enum ActivityType { send, receive, grant, airdrop, securityReject, deploy, auth }

class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final ActivityType type;
  final DateTime timestamp;
  final String signature;
  final bool isGasSponsored;
  final bool isRejected;
  final String? rejectionReason;
  final Map<String, dynamic>? metadata;

  ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
    required this.signature,
    this.isGasSponsored = true,
    this.isRejected = false,
    this.rejectionReason,
    this.metadata,
  });

  String get timeFormatted {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${timestamp.day}/${timestamp.month}';
  }

  String get shortSignature {
    if (signature.length <= 12) return signature;
    return '${signature.substring(0, 6)}...${signature.substring(signature.length - 6)}';
  }

  String get explorerUrl => 'https://explorer.solana.com/tx/$signature?cluster=devnet';
}

/// Self-Sovereign Identity permission item
class PermissionItem {
  final String name;
  final int mask;
  final String description;
  final bool isGranted;

  PermissionItem({
    required this.name,
    required this.mask,
    required this.description,
    required this.isGranted,
  });
}

/// Represents an on-chain registered organization
class OrganizationModel {
  final String id;
  final String name;
  final String domain;
  final String authorityPda;
  final String description;
  double treasuryBalance;
  final bool isSponsoring;
  int memberCount;
  int assetCount;
  final String inviteCode;
  final DateTime createdAt;
  final Color brandColor;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.domain,
    required this.authorityPda,
    required this.description,
    this.treasuryBalance = 25.0,
    this.isSponsoring = true,
    this.memberCount = 1,
    this.assetCount = 0,
    required this.inviteCode,
    required this.createdAt,
    this.brandColor = const Color(0xFF6366F1),
  });

  String get shortAuthority {
    if (authorityPda.length <= 12) return authorityPda;
    return '${authorityPda.substring(0, 6)}...${authorityPda.substring(authorityPda.length - 4)}';
  }
}

/// Represents a member within an organization with role and RBAC bitmask
class OrgMember {
  final String id;
  final String name;
  final String email;
  String role;
  int roleId;
  int permissionsMask;
  final Color avatarColor;
  final DateTime joinedAt;
  String status; // 'active', 'invited', 'suspended'
  final String identityPda;

  OrgMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleId,
    required this.permissionsMask,
    required this.avatarColor,
    required this.joinedAt,
    this.status = 'active',
    required this.identityPda,
  });

  String get shortIdentityPda {
    if (identityPda.length <= 12) return identityPda;
    return '${identityPda.substring(0, 6)}...${identityPda.substring(identityPda.length - 4)}';
  }

  bool hasPermission(int bitmask) => (permissionsMask & bitmask) != 0;
}

/// Proposal status for Proof of Authority (PoA) governance
enum ProposalStatus { pending, approved, executed, rejected }

/// Proof of Authority (PoA) Consensus Proposal
class ConsensusProposalModel {
  final int proposalId;
  final String title;
  final String description;
  final String proposerName;
  final String proposerPubkey;
  final int actionType; // 1 = Assign Role, 2 = Revoke Role, 3 = Revoke Resource, 4 = Rotate Quorum
  final String targetAddress;
  final String targetLabel;
  final int requiredThreshold;
  int currentApprovals;
  final List<String> approvedBy;
  ProposalStatus status;
  final DateTime createdAt;
  final bool isBiometricGated;

  ConsensusProposalModel({
    required this.proposalId,
    required this.title,
    required this.description,
    required this.proposerName,
    required this.proposerPubkey,
    required this.actionType,
    required this.targetAddress,
    required this.targetLabel,
    required this.requiredThreshold,
    required this.currentApprovals,
    required this.approvedBy,
    this.status = ProposalStatus.pending,
    required this.createdAt,
    this.isBiometricGated = true,
  });

  bool get isApproved => currentApprovals >= requiredThreshold;
  bool get isPending => status == ProposalStatus.pending;
  bool get isExecuted => status == ProposalStatus.executed;
  bool get isRejected => status == ProposalStatus.rejected;

  String get shortTargetAddress {
    if (targetAddress.length <= 12) return targetAddress;
    return '${targetAddress.substring(0, 6)}...${targetAddress.substring(targetAddress.length - 4)}';
  }
}

/// Proof of Authority Quorum Configuration
class QuorumConfigModel {
  final int threshold;
  final int totalAuthorities;
  final List<String> authorityNames;
  final List<String> authorityPubkeys;
  final bool biometricEnclaveActive;

  QuorumConfigModel({
    this.threshold = 2,
    this.totalAuthorities = 3,
    required this.authorityNames,
    required this.authorityPubkeys,
    this.biometricEnclaveActive = true,
  });
}


