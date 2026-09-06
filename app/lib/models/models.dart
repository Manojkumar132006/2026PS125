import 'package:flutter/material.dart';

enum StepStatus { idle, running, passed, rejected }

class ScenarioStep {
  final int step;
  final String title;
  final String description;
  StepStatus status;
  String? txSignature;
  String? eventName;
  String? note;

  ScenarioStep({
    required this.step,
    required this.title,
    required this.description,
    this.status = StepStatus.idle,
    this.txSignature,
    this.eventName,
    this.note,
  });
}

class AuditEvent {
  final String name;
  final DateTime timestamp;
  final String signature;
  final Map<String, dynamic> payload;

  AuditEvent({
    required this.name,
    required this.timestamp,
    required this.signature,
    required this.payload,
  });

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class PdaItem {
  final String title;
  final String seeds;
  final String address;
  final Map<String, String> properties;
  final Color accentColor;

  PdaItem({
    required this.title,
    required this.seeds,
    required this.address,
    required this.properties,
    required this.accentColor,
  });
}

enum ActorPersona {
  authority,
  identityA,
  identityB,
  attacker,
}

extension ActorPersonaExt on ActorPersona {
  String get displayName {
    switch (this) {
      case ActorPersona.authority:
        return 'Org Authority (Admin)';
      case ActorPersona.identityA:
        return 'Identity A (Asset Manager)';
      case ActorPersona.identityB:
        return 'Identity B (Resource Owner)';
      case ActorPersona.attacker:
        return 'Unauthorized Actor (Attacker)';
    }
  }

  String get badgeText {
    switch (this) {
      case ActorPersona.authority:
        return 'ADMIN';
      case ActorPersona.identityA:
        return 'MANAGER (0x2F)';
      case ActorPersona.identityB:
        return 'OWNER';
      case ActorPersona.attacker:
        return 'UNAUTHORIZED';
    }
  }
}
