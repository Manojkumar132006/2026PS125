# Fort System Architecture Specification

## 1. Architectural Overview

**Fort** is an enterprise-grade decentralized digital identity, asset ownership, and access governance system built on the **Solana** blockchain. It bridges Web2 enterprise identity primitives (work emails, Google OAuth, biometrics) with cryptographic, self-sovereign, on-chain execution without requiring end-users to manage gas fees or private key seed phrases.

```
                      +---------------------------------------------------+
                      |                 FORT CLIENT (APP)                 |
                      |  - Biometric Key Derivation (local_auth/FaceID)   |
                      |  - Google OAuth / Work Email OTP                  |
                      |  - Gasless Relayer Integration (0 SOL Balance)    |
                      +-------------------------+-------------------------+
                                                |
                              RPC JSON / Signed Transactions
                                                |
                                                v
                      +---------------------------------------------------+
                      |            SOLANA RUNTIME (PROGRAM DEVNET)        |
                      |        Program ID: FPMb6CKZ6hnpjSZ1WgkVTo...      |
                      +----+--------------------+--------------------+----+
                           |                    |                    |
                           v                    v                    v
                  +-----------------+  +-----------------+  +-----------------+
                  | Organization    |  | Self-Sovereign  |  | Proof of        |
                  | Authority &     |  | Identity & Key  |  | Authority (PoA) |
                  | Access Grants   |  | Recovery PDA    |  | Multi-Sig Quorum|
                  +--------+--------+  +--------+--------+  +--------+--------+
                           |                    |                    |
                           +----------+---------+--------------------+
                                      |
                                      v
                      +---------------------------------------------------+
                      |              STATE & PROVENANCE PDAs              |
                      |  - OwnershipRecord (Genesis -> P2P Transfers)     |
                      |  - CustomRole (64-bit Permission Bitmasks)        |
                      |  - Team & TeamMember (Whole-Team Inheritance)     |
                      |  - Resources (Native Program-Derived Assets)      |
                      +---------------------------------------------------+
```

---

## 2. Program Derived Address (PDA) Derivations

All accounts in Fort are deterministic **Program Derived Addresses (PDAs)** owned by the Anchor program. No tokens (SPL/Metaplex) or external program dependencies are required.

```text
Program ID: FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M
  │
  ├── Organization PDA: [b"organization"]
  │
  ├── Identity PDA: [b"identity", controller_pubkey]
  │
  ├── Identity Recovery PDA: [b"recovery", identity.key()]
  │
  ├── Resource PDA: [b"resource", organization.key(), resource_id.to_le_bytes()]
  │
  ├── Role PDA (Predefined): [b"role", organization.key(), &[role_id]]
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

## 3. On-Chain Data Layouts & Account Schemas

All new account structs are engineered for enterprise extensibility with an explicit `version: u8` field and reserved byte padding (`[u8; 16]` or `[u8; 32]`) to facilitate seamless future struct migrations.

### 3.1 `OwnershipRecord` (Provenance Engine)
Records immutable ownership provenance across each asset's lifecycle.
```rust
#[account]
pub struct OwnershipRecord {
    pub resource: Pubkey,                     // 32 B: Resource PDA
    pub sequence_number: u64,                 //  8 B: Sequence index (0 = Genesis)
    pub previous_owner: Pubkey,               // 32 B: Prior owner PDA (default for genesis)
    pub new_owner: Pubkey,                    // 32 B: Current owner Identity PDA
    pub timestamp: i64,                       //  8 B: Block Unix timestamp
    pub tx_signature: [u8; 64],               // 64 B: Cryptographic tx signature
    pub biometric_signature_proof: [u8; 32],  // 32 B: Local biometric authentication proof
    pub gas_sponsor: Pubkey,                  // 32 B: Fee payer paying rent and gas
    pub transfer_memo: [u8; 64],              // 64 B: Human-readable memo
    pub version: u8,                          //  1 B: Account schema version (v1)
    pub bump: u8,                             //  1 B: Canonical PDA bump
    pub reserved: [u8; 30],                   // 30 B: Reserved migration padding
}
```

### 3.2 `CustomRole` (Granular Bitmask Engine)
Enables organization administrators to construct tailor-made enterprise roles.
```rust
#[account]
pub struct CustomRole {
    pub organization: Pubkey,                 // 32 B: Parent organization
    pub role_id: u8,                          //  1 B: Unique role identifier within org
    pub name: [u8; 32],                       // 32 B: UTF-8 encoded role name
    pub permissions: u64,                     //  8 B: 64-bit permission bitmask
    pub created_at: i64,                      //  8 B: Creation timestamp
    pub version: u8,                          //  1 B: Schema version
    pub bump: u8,                             //  1 B: Canonical bump
    pub reserved: [u8; 14],                   // 14 B: Reserved migration padding
}
```

### 3.3 `Team` & `TeamMember` (Whole-Team Permission Inheritance)
Empowers organizations to organize identities into workgroups and bind roles to the team as an aggregate entity.
```rust
#[account]
pub struct Team {
    pub organization: Pubkey,                 // 32 B: Parent organization
    pub team_id: u8,                          //  1 B: Unique team ID
    pub name: [u8; 32],                       // 32 B: Team name (e.g., "Core Infrastructure")
    pub role_ids: [u8; 8],                    //  8 B: Up to 8 assigned custom role IDs
    pub role_count: u8,                       //  1 B: Number of active assigned roles
    pub member_count: u32,                    //  4 B: Count of active members
    pub created_at: i64,                      //  8 B: Creation timestamp
    pub version: u8,                          //  1 B: Schema version
    pub bump: u8,                             //  1 B: Canonical bump
    pub reserved: [u8; 15],                   // 15 B: Reserved migration padding
}

#[account]
pub struct TeamMember {
    pub team: Pubkey,                         // 32 B: Team PDA
    pub member_identity: Pubkey,              // 32 B: Member Identity PDA
    pub joined_at: i64,                       //  8 B: Joining timestamp
    pub version: u8,                          //  1 B: Schema version
    pub bump: u8,                             //  1 B: Canonical bump
    pub reserved: [u8; 14],                   // 14 B: Reserved migration padding
}
```

### 3.4 `IdentityRecovery` (Guardian Protocol)
Eliminates the risk of permanent identity lockout when an Ed25519 device keypair is lost or compromised.
```rust
#[account]
pub struct IdentityRecovery {
    pub identity: Pubkey,                     // 32 B: Protected Identity PDA
    pub guardians: [Pubkey; 5],               // 160 B: Up to 5 guardian public keys
    pub guardian_count: u8,                   //  1 B: Total registered guardians
    pub threshold: u8,                        //  1 B: Quorum needed (e.g., 2-of-3)
    pub recovery_in_progress: bool,           //  1 B: Active recovery flag
    pub proposed_controller: Pubkey,          // 32 B: Newly proposed device key
    pub approvals: [Pubkey; 5],               // 160 B: Guardians who have signed approval
    pub approval_count: u8,                   //  1 B: Approvals collected so far
    pub initiated_at: i64,                    //  8 B: Timestamp recovery was initiated
    pub version: u8,                          //  1 B: Schema version
    pub bump: u8,                             //  1 B: Canonical bump
    pub reserved: [u8; 30],                   // 30 B: Reserved migration padding
}
```

---

## 4. Permission Bitmask Matrix

Fort permissions are encoded in a compact 64-bit bitmask (`u64`), allowing blazing-fast bitwise verification (`(role.permissions & required) == required`) on-chain with zero deserialization overhead.

| Bit Flag | Mask | Constant Name | Description |
| :---: | :---: | :--- | :--- |
| `1 << 0` | `0x0001` | `CREATE_RESOURCE` | Create new native digital asset PDAs |
| `1 << 1` | `0x0002` | `ASSIGN_RESOURCE` | Assign initial ownership or change asset binding |
| `1 << 2` | `0x0004` | `TRANSFER_RESOURCE` | Transfer asset ownership with provenance recording |
| `1 << 3` | `0x0008` | `REVOKE_RESOURCE` | Freeze, decommission, or revoke an asset |
| `1 << 4` | `0x0010` | `MANAGE_ROLES` | Create custom roles, teams, and adjust permissions |
| `1 << 5` | `0x0020` | `VERIFY` | Audit cryptographic provenance and identity proofs |
| `1 << 6` | `0x0040` | `DELEGATE` | Delegate access grants to secondary identities |
| `1 << 7` | `0x0080` | `EXECUTE_ACTION` | Trigger smart contract executions or PoA proposals |

---

## 5. Security Architecture & Trust Boundaries

1. **Client Isolation**: The client stores zero persistent private keys in plaintext. Ephemeral transaction keys are derived on-the-fly or guarded inside the Android Keystore / iOS Secure Enclave backed by biometrics.
2. **Zero-Gas Architecture**: Transactions use a dual-signature model:
   - **Fee Payer (Gas Sponsor)**: Pays Solana network rent and micro-lamport compute fees.
   - **Authority / Controller**: Signs instructions to prove self-sovereign intent.
   - Result: Users require **0 SOL** to operate Fort.
3. **No PII On-Chain**: Emails and names are never stored on-chain. Identity commitments utilize `HMAC-SHA256(email, organization_secret_salt)`. "Right to be forgotten" is fulfilled via off-chain crypto-shredding.
