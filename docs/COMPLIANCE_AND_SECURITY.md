# Fort Compliance & Enterprise Security Architecture

## 1. Executive Summary

Enterprise adoption of public blockchain rails faces five critical technical and regulatory hurdles:
1. **Permanent Lockout Risk**: Traditional Web3 non-custodial wallets result in permanent asset loss upon device or private key loss.
2. **Data Privacy Regulations (GDPR & DPDP)**: Public blockchain immutability conflicts directly with the "Right to be Forgotten".
3. **Single Point of Takeover**: Single-key admin structures expose the entire enterprise to catastrophic takeover upon credential phishing or device theft.
4. **Gas Mechanics & UX Friction**: Demanding end-users buy and manage volatile cryptocurrency (SOL) to pay transaction fees blocks mainstream non-crypto employees.
5. **On-Chain Schema Rigidity**: Upgrading PDA account layouts without breaking live state is notoriously difficult on Solana.

**Fort** resolves all five challenges through mathematical, architectural, and protocol-level guarantees.

---

## 2. Risk 1: Device / Key Loss & Guardian Key-Rotation Protocol

### Threat Model
An employee's physical device is lost, destroyed, or their local keypair is corrupted. In traditional decentralized architectures, this locks the user out permanently, orphaning all company assets, access grants, and organizational credentials.

### Fort Resolution
- **Identity PDA Decoupling**: The user's Identity is not their public key; it is a Program Derived Address (PDA) derived from `[b"identity", controller_pubkey]`.
- **$K$-of-$N$ Guardian Quorum**: The employee (or organization policy) registers up to 5 trusted guardians (e.g., Company IT Security, Team Lead, Corporate HSM, Backup Key) and configures a threshold (e.g., 2-of-3).
- **On-Chain Key Rotation**:
  1. A guardian detects lockout and triggers `initiate_identity_recovery(new_device_key)`.
  2. Guardians inspect and cryptographically sign `approve_identity_recovery()` via their authentic credentials.
  3. Once the threshold is satisfied, `execute_identity_recovery()` rotates `Identity.controller` to the new device key.
- **Outcome**: The user's Identity PDA address remains identical. Zero assets are burned, zero access grants need re-issuing, and lockout is eliminated.

---

## 3. Risk 2: GDPR & India DPDP Act 2023 Compliance (Zero-PII On-Chain)

### Regulatory Conflict
- **GDPR Article 17 ("Right to Erasure / Right to be Forgotten")** and **India DPDP Act 2023 (Section 12)** mandate that data fiduciaries must erase personal data upon withdrawal of consent.
- Solana transaction logs and account states are immutable and globally replicated across thousands of validator nodes.

### Fort Resolution
- **Zero Raw PII Storage**: Names, personal email addresses, phone numbers, and biological biometric scans are **never** written to Solana account storage or instruction logs.
- **Cryptographic Blind Commitments**:
  $$\text{Commitment} = \text{HMAC-SHA256}(\text{WorkEmail}, \text{OrganizationSalt})$$
- **Off-Chain Crypto-Shredding**:
  1. The salt is maintained in the enterprise's access-controlled key management service (AWS KMS / HashiCorp Vault).
  2. Upon an employee's departure or GDPR erasure request, the salt corresponding to their identifier is shredded (permanently deleted).
  3. Without the salt, the on-chain commitment is mathematically irreversible, rendering the on-chain record permanently de-linked from natural persons.
  4. Complies fully with European Data Protection Board (EDPB) guidelines on irreversible anonymization.

---

## 4. Risk 3: Single Authority Key Takeover & PoA Quorum Consensus

### Threat Model
An organization administrator's laptop or private key is compromised via malware or SIM-swapping. An attacker could unilaterally siphon treasury assets, delete access grants, or revoke employee identities.

### Fort Resolution
- **Proof of Authority ($M$-of-$N$) Multi-Sig Gating**:
  - High-risk operations (modifying base organization parameters, emergency shutdowns, global revocation) cannot be executed by any single key.
  - A dedicated `PoAConfig` PDA designates $N$ authorized council keys (e.g., CISO, Head of Infrastructure, Compliance Officer) with a strict quorum threshold $M$ (e.g., 2-of-3 or 3-of-5).
- **Proposal Lifecycle**:
  1. Any authority proposes an action (`create_proposal`).
  2. Council authorities inspect proposal details and cast signed on-chain votes (`vote_proposal`).
  3. Only when threshold approvals are verifiably accumulated can `execute_proposal` be triggered by the Solana runtime.

---

## 5. Risk 4: Gas Mechanics & Enterprise UX Friction

### UX Problem
Expecting enterprise staff (e.g., HR, legal, sales) to acquire SOL from crypto exchanges, maintain private seed phrases, and calculate gas fees results in 99% employee rejection.

### Fort Resolution
- **100% Sponsored Gas Architecture**:
  - All instructions accept a separate `fee_payer` signer account (`[mut, Signer<'info>]`).
  - Enterprise relayer nodes co-sign transactions as the fee payer, paying Solana rent and micro-lamport prioritization fees.
  - Employees only sign with their device controller key (via fingerprint/FaceID or secure enclave).
  - Employees require **0 SOL** in their balance.
- **Optimistic State & Local Caching**:
  - Flutter client maintains an optimistic local write-ahead log.
  - Prevents UI freezing or RPC timeouts during public devnet/mainnet network congestion.

---

## 6. Risk 5: On-Chain Account Migration & Versioning

### Upgrade Vulnerability
Adding fields to Solana account structs causes account size expansion. If existing accounts allocated with fixed byte sizes are read with new struct definitions, deserialization fails with `AccountDidNotDeserialize` errors.

### Fort Resolution
Every newly introduced state struct in Fort is built with forward compatibility:
1. **Explicit Schema Versioning**: `pub version: u8` field at the head of the struct.
2. **Reserved Migration Byte Padding**:
   - `reserved: [u8; 14]`, `[u8; 15]`, or `[u8; 30]`.
   - Allows future Anchor program upgrades to unpack new fields from the reserved byte buffer without reallocating account sizes or needing rent-exemption top-ups.
