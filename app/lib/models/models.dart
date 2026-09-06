import 'package:flutter/material.dart';

/// Represents a connected Solana wallet account
class WalletAccount {
  final String label;
  final String publicKey;
  final String identityPda;
  final String role;
  final int permissionsMask;
  double solBalance;
  final Color avatarColor;
  final bool isSponsored;

  WalletAccount({
    required this.label,
    required this.publicKey,
    required this.identityPda,
    required this.role,
    required this.permissionsMask,
    this.solBalance = 0.0,
    required this.avatarColor,
    this.isSponsored = true,
  });

  String get shortPublicKey {
    if (publicKey.length <= 10) return publicKey;
    return '${publicKey.substring(0, 4)}...${publicKey.substring(publicKey.length - 4)}';
  }

  String get shortIdentityPda {
    if (identityPda.length <= 10) return identityPda;
    return '${identityPda.substring(0, 4)}...${identityPda.substring(identityPda.length - 4)}';
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
enum ActivityType { send, receive, grant, airdrop, securityReject, deploy }

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

/// Self-Sovereign Identity permission model
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
