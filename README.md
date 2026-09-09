# Fort: Decentralized Enterprise Identity, Asset Provenance & Governance

<div align="center">

```
  ███████╗ ██████╗ ██████╗ ████████╗
  ██╔════╝██╔═══██╗██╔══██╗╚══██╔══╝
  █████╗  ██║   ██║██████╔╝   ██║   
  ██╔══╝  ██║   ██║██╔══██╗   ██║   
  ██║     ╚██████╔╝██║  ██║   ██║   
  ╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   
```

**Next-Generation Self-Sovereign Identity, Cryptographic Asset Provenance & Role-Based Access Control on Solana**

[![Solana Devnet](https://img.shields.io/badge/Solana-Devnet-14F195?logo=solana&logoColor=black)](https://explorer.solana.com/address/FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M?cluster=devnet)
[![Anchor Framework](https://img.shields.io/badge/Anchor-0.32.1-3B82F6?logo=rust)](https://www.anchor-lang.com)
[![Tests Passing](https://img.shields.io/badge/Tests-57%20Passing-10B981)](#test-suite-results)
[![Gas Fees](https://img.shields.io/badge/User%20Gas-0%20SOL%20(Sponsored)-8B5CF6)](#zero-gas-relayers)
[![Compliance](https://img.shields.io/badge/Compliance-GDPR%20%2F%20DPDP%20Zero--PII-06B6D4)](#zero-pii-compliance)

</div>

---

## 1. Live Solana Devnet Deployment

The Fort smart contracts are compiled and deployed to the **Solana Devnet** cluster:

| Component | Identifier | Solana Explorer Link |
| :--- | :--- | :--- |
| **Program ID** | `FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M` | [View Program on Solana Explorer](https://explorer.solana.com/address/FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M?cluster=devnet) |
| **ProgramData Account** | `FMZDd8p6SBwThLmEeXazBedXB7aGEvfP7GLADbxYKd5A` | [View ProgramData Account](https://explorer.solana.com/address/FMZDd8p6SBwThLmEeXazBedXB7aGEvfP7GLADbxYKd5A?cluster=devnet) |
| **Upgrade Tx Signature** | `98SwyikW4j37EobY46zgw...` (Slot 495547121) | [View Upgrade Transaction](https://explorer.solana.com/tx/98SwyikW4j37EobY46zgwG3ahhbKoGwYofkb18puokxf2ppSfrUoa2TdjuNN6NmzS9MHosp27fozbur2eFRvTmf?cluster=devnet) |
| **Genesis Deploy Tx** | `2YMLcHTYoMoaw6CQiDG...` (Slot 494095229) | [View Genesis Deploy Transaction](https://explorer.solana.com/tx/2YMLcHTYoMoaw6CQiDGfHjnUrjw2DkKqQfducTBJysU3vPmEXgpy2Mz36Sbgxe9wRDvskxhLNKRywADakRWMakE1?cluster=devnet) |
| **Upgrade Authority** | `B7dKfnjjpBmYrakj5j44nF4moQpZ8LHasAe7veUpNYUh` | [View Authority Account](https://explorer.solana.com/address/B7dKfnjjpBmYrakj5j44nF4moQpZ8LHasAe7veUpNYUh?cluster=devnet) |
| **Cluster Endpoint** | `https://api.devnet.solana.com` | `confirmed` commitment |

---

## 2. Core Pillars of Fort

### 🛡️ 1. Self-Sovereign Identity & Biometric Key Derivation
- Eliminates private key seed phrases. Device keys are derived locally through hardware-backed biometrics (Fingerprint / FaceID / Secure Enclave).
- Users control a unique, native on-chain `Identity` PDA derived from `[b"identity", controller.key()]`.

### 📜 2. Asset Ownership Provenance Engine
- Every digital asset maintains an immutable, cryptographically verifiable chain of custody recorded on-chain in sequential `OwnershipRecord` PDAs.
- Sequence starts from Genesis (`seq = 0`) on asset creation, continuing monotonically through peer-to-peer transfers with biometric verification proofs, gas-sponsor audit records, and transfer memos.

### 👥 3. Teams & Whole-Team Custom Role Inheritance
- Enterprise admins can create custom roles with customizable 64-bit permission bitmasks (`CREATE_RESOURCE`, `TRANSFER`, `MANAGE_ROLES`, etc.).
- Workgroups (Teams) can be assigned multiple custom roles. All members enrolled in a team automatically inherit the bitwise union of all team permissions without per-member transaction bloat.

### 🗳️ 4. Proof of Authority (PoA) Multi-Sig Quorum
- Destructive operations (emergency lockdowns, treasury mutations, admin revokes) are gated behind an on-chain $M$-of-$N$ PoA council consensus module (`PoAConfig`, `Proposal`, `Vote`).

### 🔑 5. Identity Guardian Key Recovery Protocol
- Resolves the existential risk of Web3 key loss: if an employee loses their device or keypair, registered guardians can vote to rotate the controlling public key **without altering the Identity PDA address or losing owned assets**.

### 🔒 6. Zero-PII Compliance (GDPR Article 17 & India DPDP Act 2023)
- No plaintext PII is committed to Solana state or instruction logs. Identities use `HMAC-SHA256(email, salt)`.
- Fulfills the "Right to be Forgotten" via off-chain crypto-shredding: destroying the secret salt mathematically irreversibilizes on-chain commitments.

### ⚡ 7. 100% Sponsored Gas Architecture (0 SOL User Balances)
- Transactions feature a dual-signer design: the user's controller signs the instruction, while the organization relayer acts as `fee_payer` paying network fees and account rent. Users interact with 0 SOL.

---

## 3. Architecture & PDA Derivations

```text
Fort Program ID: FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M
  │
  ├── Organization PDA: [b"organization"]
  │
  ├── Identity PDA: [b"identity", controller_pubkey]
  │
  ├── Identity Recovery PDA: [b"recovery", identity.key()]
  │
  ├── Resource PDA: [b"resource", organization.key(), resource_id.to_le_bytes()]
  │
  ├── Role PDA: [b"role", organization.key(), &[role_id]]
  │
  ├── CustomRole PDA: [b"custom-role", organization.key(), &[role_id]]
  │
  ├── Team PDA: [b"team", organization.key(), &[team_id]]
  │
  ├── TeamMember PDA: [b"team-member", team.key(), member_identity.key()]
  │
  ├── OwnershipRecord PDA: [b"ownership-record", resource.key(), sequence_number.to_le_bytes()]
  │
  ├── AccessGrant PDA: [b"grant", identity.key(), resource.key(), role.key()]
  │
  ├── PoAConfig PDA: [b"poa-config", organization.key()]
  │
  ├── Proposal PDA: [b"proposal", organization.key(), proposal_id.to_le_bytes()]
  │
  └── Vote PDA: [b"vote", proposal.key(), authority.key()]
```

---

## 4. Test Suite Results

The comprehensive Anchor integration test suite validates all 23 on-chain instructions:

```
  identity-registry
    ✔ initializes organization (452ms)
    ✔ fails to initialize with empty name (37ms)
    ✔ creates identity with biometric commitment (465ms)
    ✔ creates identity without biometric commitment (451ms)
    ✔ updates identity metadata (461ms)
    ✔ revokes identity (460ms)
    ✔ creates access grant with role and permissions (459ms)
    ✔ delegates access grant (460ms)
    ✔ revokes access grant (453ms)
    ✔ rotates authority key (455ms)
    ✔ updates metadata hash (463ms)
    ✔ creates resources across multiple organizations (921ms)
    ✔ validates cross-organization access isolation (472ms)
    ✔ creates PoA config with 3 authorities and threshold 2 (458ms)
    ✔ creates PoA proposal for emergency shutdown (459ms)
    ✔ authority 1 votes yes on proposal (460ms)
    ✔ authority 2 votes yes on proposal (threshold reached) (456ms)
    ✔ executes approved proposal (457ms)
    ✔ records genesis ownership on asset mint (462ms)
    ✔ records secondary ownership transfer with biometric proof (470ms)
    ✔ creates custom roles with fine-grained permission bitmasks (464ms)
    ✔ creates team under organization (461ms)
    ✔ assigns custom roles to team (465ms)
    ✔ adds member to team (460ms)
    ✔ configures identity recovery with 2-of-3 guardians (462ms)
    ✔ initiates recovery request for compromised key (459ms)
    ✔ guardian approves recovery request (458ms)
    ✔ guardian 2 approves recovery and executes key rotation (471ms)
    ... (29 additional edge case & security boundary tests)

  57 passing (33s)
```

---

## 5. Documentation Directory

Detailed specifications, IDL documentation, and enterprise compliance guides:

- 📘 [**docs/ARCHITECTURE.md**](docs/ARCHITECTURE.md): In-depth system architecture, PDA derivation tree, account schemas, and security model.
- 📜 [**docs/SMART_CONTRACTS.md**](docs/SMART_CONTRACTS.md): Complete smart contract instruction signatures, accounts, parameters, error codes, and TypeScript client integration.
- ⚖️ [**docs/COMPLIANCE_AND_SECURITY.md**](docs/COMPLIANCE_AND_SECURITY.md): Enterprise risk mitigations (Guardian Key Recovery, GDPR/DPDP Zero-PII, PoA Quorum Consensus, 0-SOL Relayers, PDA Struct Migration).
- 📱 [**app/README.md**](app/README.md): Flutter mobile client guide, UI architecture, biometric authentication, release APK build instructions.

---

## 6. Quickstart Guide

### Prerequisites
- [Rust](https://www.rust-lang.org/tools/install) `1.89.0`
- [Solana CLI](https://docs.solanalabs.com/cli/install) `4.2.2` (Agave)
- [Anchor Framework](https://www.anchor-lang.com/docs/installation) `0.32.1`
- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.13.2`

### 1. Build Smart Contracts
```bash
anchor build
```

### 2. Run Integration Tests
```bash
anchor test
```

### 3. Launch Flutter Mobile App
```bash
cd app
flutter pub get
flutter run
```

### 4. Build Android Release APK
```bash
cd app
flutter build apk --release
# Outputs: build/app/outputs/flutter-apk/app-release.apk
```
