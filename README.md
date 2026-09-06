# Solana Decentralized Identity, Asset Ownership, RBAC & Audit System (MVP)

A minimal, production-structured prototype on **Solana** demonstrating:
1. **Decentralized Digital Identity**: Self-sovereign identity controlled exclusively by the user's cryptographic keypair. Zero personal/biometric data on-chain.
2. **PDA-Based Digital Asset Ownership**: Digital assets represented as native Program Derived Addresses (PDAs) owned and mutated solely by the Anchor program (no NFTs, Metaplex, or SPL tokens).
3. **Trustless Authorization**: All RBAC, role hierarchy, ownership checks, and resource validations enforced directly inside the Solana runtime.
4. **Bitmask RBAC**: Compact `u64` bitmask permission engine supporting fine-grained permissions without dynamic permission PDA account bloat.
5. **Resource-Level Access Control**: Unified `AccessGrant` PDA connecting `(Identity, Resource, Role)` with active status and optional expiration timestamps.
6. **Immutable Audit Trail**: Anchor program events emitted for every state transition, providing an immutable audit log queryable via Solana transaction history.
7. **Organization-Sponsored Transactions**: Organization fee-payer architecture enabling gasless user transactions where the user signs with their private key and holds **0 SOL**.

---

## 1. Deployed Program Information (Solana Devnet)

* **Program Name**: `identity_registry`
* **Program ID**: [`FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M`](https://explorer.solana.com/address/FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M?cluster=devnet)
* **Devnet Deploy Tx Signature**: [`2YMLcHTYoMoaw6CQiDGfHjnUrjw2DkKqQfducTBJysU3vPmEXgpy2Mz36Sbgxe9wRDvskxhLNKRywADakRWMakE1`](https://explorer.solana.com/tx/2YMLcHTYoMoaw6CQiDGfHjnUrjw2DkKqQfducTBJysU3vPmEXgpy2Mz36Sbgxe9wRDvskxhLNKRywADakRWMakE1?cluster=devnet)
* **Cluster**: Solana Devnet (`https://api.devnet.solana.com`)
* **Framework**: Anchor `0.32.1`, Solana CLI `4.2.2` (Agave), Rust `1.89.0`

---

## 2. Architecture & PDA Derivations

All persistent state entities are Program Derived Addresses (PDAs). No dynamic account allocation outside of program seeds:

```text
Organization PDA: ["organization"]
       │
       ├── Identity PDA: ["identity", controller_pubkey]
       │
       ├── Resource PDA: ["resource", organization, resource_id]
       │
       └── Role PDA: ["role", organization, role_id]
                  │
                  └── AccessGrant PDA: ["grant", identity, resource, role]
```

### Account Structures & Space Allocation

| Account | PDA Seeds | Size | Fields |
| :--- | :--- | :--- | :--- |
| **Organization** | `[b"organization"]` | 41 B | `authority: Pubkey`, `bump: u8` |
| **Identity** | `[b"identity", controller.as_ref()]` | 50 B | `controller: Pubkey`, `status: u8`, `created_at: i64`, `bump: u8` |
| **Role** | `[b"role", organization.as_ref(), &[role_id]]` | 50 B | `organization: Pubkey`, `role_id: u8`, `permissions: u64`, `bump: u8` |
| **Resource** | `[b"resource", organization.as_ref(), &resource_id.to_le_bytes()]` | 91 B | `organization: Pubkey`, `resource_id: u64`, `owner: Pubkey`, `resource_type: u8`, `status: u8`, `created_at: i64`, `bump: u8` |
| **AccessGrant** | `[b"grant", identity.as_ref(), resource.as_ref(), role.as_ref()]` | 114 B | `identity: Pubkey`, `resource: Pubkey`, `role: Pubkey`, `active: bool`, `expires_at: i64`, `bump: u8` |

> [!NOTE]
> The `AccessGrant` PDA seamlessly models both:
> 1. **Organization-level roles**: where `resource` is the `Organization` PDA (e.g. Identity A assigned `ASSET_MANAGER` within the Organization).
> 2. **Resource-level access**: where `resource` is the `Resource` PDA (e.g. Identity A granted operational access to Resource #1).

---

## 3. Bitmask RBAC & Permissions

Permissions are modeled as an efficient 64-bit mask:

```rust
pub const CREATE_RESOURCE: u64   = 1 << 0; // 0x01 (1)
pub const ASSIGN_RESOURCE: u64   = 1 << 1; // 0x02 (2)
pub const TRANSFER_RESOURCE: u64 = 1 << 2; // 0x04 (4)
pub const REVOKE_RESOURCE: u64   = 1 << 3; // 0x08 (8)
pub const MANAGE_ROLES: u64      = 1 << 4; // 0x10 (16)
pub const VERIFY: u64            = 1 << 5; // 0x20 (32)
```

Standard Pre-configured Roles:
* **ADMIN (`role_id: 1`)**: All permissions (`0x3F` = 63)
* **ASSET_MANAGER (`role_id: 2`)**: `CREATE_RESOURCE | ASSIGN_RESOURCE | TRANSFER_RESOURCE | REVOKE_RESOURCE | VERIFY` (`0x2F` = 47)
* **AUDITOR (`role_id: 3`)**: `VERIFY` (`0x20` = 32)

---

## 4. Trustless On-Chain Authorization Flow

The frontend or relayers **never** make authorization decisions. Every protected operation routes through the centralized on-chain helper:

```rust
require_permission(
    identity: &Account<Identity>,
    controller: &Signer,
    resource: &Pubkey,
    grant: &Account<AccessGrant>,
    role: &Account<Role>,
    required_permission: u64,
    current_time: i64,
) -> Result<()>
```

Execution Checklist:
1. **Signer Verification**: `identity.controller == controller.key()`.
2. **Identity Liveness**: `identity.status == STATUS_ACTIVE (1)`.
3. **Grant Validity**: `grant.identity == identity.key() && grant.resource == *resource && grant.role == role.key()`.
4. **Grant Liveness**: `grant.active == true`.
5. **Expiration Guard**: `grant.expires_at == 0 || current_time < grant.expires_at`.
6. **Bitmask Match**: `(role.permissions & required_permission) == required_permission`.

---

## 5. Organization-Sponsored Transactions (Gasless User Flow)

The system supports zero-balance end users:
1. User generates a self-sovereign ed25519 keypair (`controller`).
2. The transaction specifies:
   * `feePayer = organization_wallet.publicKey`
   * `instructions = [program.createIdentity(...)]`
3. The User signs the transaction as `controller` (providing cryptographic proof of intent).
4. The Organization wallet signs as `payer` (paying rent + gas fee).
5. Result: The user wallet balance remains **0 SOL**, while the Identity PDA and permissions are fully established on Solana.

---

## 6. Emitted Audit Trail Events

The program emits Anchor events for all state-changing actions:

* `IdentityCreated { identity, controller, created_at }`
* `RoleCreated { organization, role, role_id, permissions }`
* `RoleAssigned { organization, identity, role }`
* `RoleRevoked { organization, identity, role }`
* `ResourceCreated { organization, resource, resource_id, owner, resource_type, created_at }`
* `ResourceAssigned { resource, previous_owner, new_owner }`
* `ResourceTransferred { resource, previous_owner, new_owner }`
* `ResourceRevoked { resource, revoked_by }`
* `AccessGranted { resource, identity, role, expires_at }`
* `AccessRevoked { resource, identity, role }`
* `PermissionVerified { identity, resource, role, permission }`

---

## 7. 17-Step Acceptance Test Scenario

The complete test suite verifies the exact 17-step flow specified in the project requirements:

```text
1. Initialize organization                          [PASS]
2. Create Identity A                                [PASS]
3. Create Identity B                                [PASS]
4. Create ADMIN role                                [PASS]
5. Create ASSET_MANAGER role                        [PASS]
6. Assign ASSET_MANAGER to Identity A               [PASS]
7. Create Resource #1                               [PASS]
8. Assign Resource #1 to Identity B                 [PASS]
9. Grant Identity A access to Resource #1           [PASS]
10. Identity A performs an authorized operation     [PASS]
11. Unauthorized Identity B attempts same operation [REJECTED ON-CHAIN]
12. Program rejects unauthorized operation          [PASS]
13. Transfer Resource #1 to Identity C              [PASS]
14. Revoke Resource #1                              [PASS]
15. Attempt operation on revoked Resource #1        [REJECTED ON-CHAIN]
16. Program rejects operation on revoked resource   [PASS]
17. Show emitted events & audit signatures          [30 EVENTS CAPTURED]
```

---

## 8. Running Locally & Testing

### Prerequisites
* Rust `1.89+`
* Solana CLI `4.2+`
* Anchor CLI `0.32.1`
* Node.js `20+` & Yarn

### Build & Run Tests
```bash
cd contracts

# Build Solana program & IDL
anchor build

# Run unit tests via cargo
cargo test --manifest-path programs/identity_registry/Cargo.toml

# Run full Anchor test suite against local validator
anchor test --skip-build
```

### Run the Web & Flutter Frontends

#### 1. React Web App (contracts/app)
```bash
cd contracts/app
npm install
npm run dev
# Running on http://localhost:3000
```

#### 2. Flutter App (app)
```bash
cd app
flutter pub get
flutter build web

# Serve Flutter Web App
python3 -m http.server 8080 --directory build/web
# Running on http://localhost:8080
```

---

## 9. Security Assumptions & Constraints

1. **No Sensitive Personal Data On-Chain**: Raw biometrics (e.g. fingerprints, face data) must remain local to hardware secure enclaves (e.g. WebAuthn, TouchID, Secure Enclave) and never reach Solana.
2. **Private Keys Remain Client-Side**: Neither the backend relayer nor organization authority possesses access to user private keys.
3. **No Centralized Authorization Gate**: Even if a malicious relayer alters transactions, signature checks fail; if a relayer attempts unauthorized operations, on-chain RBAC bitmasks reject the transaction.
4. **Revocation Immutability**: Once a resource status is set to `REVOKED (2)`, all transfer and operational instructions are permanently blocked by the program.
