# Fort Mobile Application (`app/`)

<div align="center">
  <h3>Enterprise Decentralized Identity, Asset Ownership & Governance</h3>
  <p>Production Flutter Client for Android & iOS</p>
</div>

---

## 1. Overview

The **Fort Mobile Application** provides an intuitive, consumer-grade user experience for managing enterprise decentralized identities, native digital assets, organizational teams, custom permissions, and multi-sig governance on **Solana**.

It completely abstracts away blockchain complexity:
- **0 SOL Required**: All transaction fees and storage rent are subsidized by the enterprise gas sponsor relayer.
- **Biometric Authentication**: Leverages Android BiometricPrompt / iOS FaceID via `local_auth` to authenticate and derive on-chain signatures without exposing private keys.
- **Enterprise Single Sign-On**: Seamless Google OAuth and Work Email OTP login flows.

---

## 2. Key Screen & Component Breakdown

```text
app/lib/
  ├── main.dart                          # FortApp root entrypoint & dark theme configuration
  ├── theme/
  │   └── app_theme.dart                 # Obsidian glassmorphic palette, typography & tokens
  ├── models/
  │   └── models.dart                    # Type-safe models: User, Resource, Team, CustomRole, Provenance
  ├── services/
  │   └── solana_service.dart            # Solana RPC client, gas relayer, optimistic state engine
  ├── screens/
  │   ├── auth_screen.dart               # Enterprise SSO (Google OAuth, Work Email OTP, biometrics)
  │   ├── create_organization_screen.dart# On-chain Organization bootstrapping workflow
  │   └── admin_organization_screen.dart # High-level organization governance dashboard
  └── widgets/
      ├── wallet_header.dart             # Holographic user status, network pill & profile drawer
      ├── balance_card.dart              # Sponsored gas indicator (0 SOL) & quick action buttons
      ├── digital_assets_view.dart       # Interactive grid of native on-chain digital assets
      ├── ownership_provenance_modal.dart# Stepped cryptographic ownership timeline modal
      ├── identity_pass_view.dart        # Holographic identity pass & Guardian key-recovery card
      ├── admin_hub_view.dart            # Teams, Custom Roles builder & GDPR compliance card
      ├── activity_feed_view.dart        # Real-time event log with Solana Explorer link verification
      ├── transfer_modal.dart            # P2P asset transfer with biometric confirmation
      └── receive_modal.dart             # QR code & copyable Identity PDA share sheet
```

---

## 3. Core Capabilities

### 3.1 Biometric Key Derivation & Protection
- Users authorize operations with standard fingerprint or facial recognition (`local_auth: ^2.3.0`).
- Generates a local 32-byte biometric commitment proof attached to each transaction instruction.

### 3.2 Stepped Ownership Provenance Modal
- Inspects complete asset lifecycle from Genesis mint (`seq = 0`) to subsequent transfers.
- Displays previous owner, new owner, Unix timestamp, biometric verification badge, 0-SOL gas badge, and transaction signatures linked directly to the Solana Explorer.

### 3.3 Teams & Custom Roles Engine
- Admins create enterprise workgroups and custom roles with fine-grained 64-bit permission bitmasks (`0x01` through `0x80`).
- Roles assigned to a team are automatically inherited by all active team members.

### 3.4 Identity Guardian & Key Recovery
- Safeguards employees against device loss or key corruption.
- Users configure $K$-of-$N$ guardians who can vote to rotate the controlling device key on-chain without altering the user's Identity PDA address or losing digital assets.

### 3.5 GDPR Article 17 & DPDP Act 2023 Compliance
- Zero PII is committed to Solana blocks.
- Real-time audit card in Admin Hub demonstrating `HMAC-SHA256` commitment hashing and off-chain crypto-shredding.

---

## 4. Building and Running

### Prerequisites
- Flutter SDK `^3.13.2` or later
- Android SDK with Platform Tools (`adb`)
- Connected physical Android device (with developer mode enabled) or Android Emulator (`emulator-5554`)

### Run in Debug Mode
```bash
flutter run
```

### Run Linter & Static Analysis
```bash
flutter analyze
```

### Build Production Release APK
```bash
flutter build apk --release
```
The compiled release binary is generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Install onto Device / Emulator via ADB
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am start -n com.solana.identityregistry/com.example.app.MainActivity
```
