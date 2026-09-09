# Fort Smart Contracts Reference (`identity_registry`)

## 1. Program Specifications

* **Program Name**: `identity_registry`
* **Program ID**: [`FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M`](https://explorer.solana.com/address/FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M?cluster=devnet)
* **ProgramData Account**: [`FMZDd8p6SBwThLmEeXazBedXB7aGEvfP7GLADbxYKd5A`](https://explorer.solana.com/address/FMZDd8p6SBwThLmEeXazBedXB7aGEvfP7GLADbxYKd5A?cluster=devnet)
* **Upgrade Tx Signature**: [`98SwyikW4j37EobY46zgwG3ahhbKoGwYofkb18puokxf2ppSfrUoa2TdjuNN6NmzS9MHosp27fozbur2eFRvTmf`](https://explorer.solana.com/tx/98SwyikW4j37EobY46zgwG3ahhbKoGwYofkb18puokxf2ppSfrUoa2TdjuNN6NmzS9MHosp27fozbur2eFRvTmf?cluster=devnet)
* **Genesis Deploy Tx Signature**: [`2YMLcHTYoMoaw6CQiDGfHjnUrjw2DkKqQfducTBJysU3vPmEXgpy2Mz36Sbgxe9wRDvskxhLNKRywADakRWMakE1`](https://explorer.solana.com/tx/2YMLcHTYoMoaw6CQiDGfHjnUrjw2DkKqQfducTBJysU3vPmEXgpy2Mz36Sbgxe9wRDvskxhLNKRywADakRWMakE1?cluster=devnet)
* **Target Cluster**: Solana Devnet (`https://api.devnet.solana.com`)
* **Framework**: Anchor `0.32.1`, Solana CLI `4.2.2` (Agave), Rust `1.89.0`

---

## 2. Instruction Reference

### 2.1 Core Identity & Organization

#### `initialize_organization(name: String)`
Initializes the root singleton Organization PDA with the caller as the founding authority.
- **Seeds**: `[b"organization"]`
- **Accounts**:
  - `organization`: `[init, payer = authority, space = Organization::LEN]`
  - `authority`: `[signer, mut]`
  - `system_program`: `Program<'info, System>`

#### `create_identity(identity_hash: [u8; 32], biometric_commitment: [u8; 32])`
Creates a self-sovereign Identity PDA. No PII is stored on-chain.
- **Seeds**: `[b"identity", controller.key().as_ref()]`
- **Accounts**:
  - `identity`: `[init, payer = fee_payer, space = Identity::LEN]`
  - `controller`: `Signer<'info>` (User's cryptographic key)
  - `fee_payer`: `[mut, Signer<'info>]` (Gas sponsor or user)
  - `system_program`: `Program<'info, System>`

#### `rotate_authority(new_controller: Pubkey)`
Rotates the user's controlling public key when initiated by the current active controller.
- **Seeds**: `[b"identity", controller.key().as_ref()]`

---

### 2.2 Asset Ownership & Provenance

#### `record_ownership_transfer(sequence_number: u64, previous_owner: Pubkey, new_owner: Pubkey, tx_signature: [u8; 64], biometric_signature_proof: [u8; 32], memo: [u8; 64])`
Writes an immutable sequential audit record of asset ownership.
- **Seeds**: `[b"ownership-record", resource.key().as_ref(), sequence_number.to_le_bytes().as_ref()]`
- **Validation**:
  - `sequence_number == 0`: Genesis mint; `previous_owner` can be default pubkey.
  - `sequence_number > 0`: Verifies `previous_owner` matches current asset owner.
- **Accounts**:
  - `resource`: `Account<'info, Resource>`
  - `ownership_record`: `[init, payer = fee_payer, space = OwnershipRecord::LEN]`
  - `caller_identity`: `Account<'info, Identity>`
  - `controller`: `Signer<'info>`
  - `fee_payer`: `[mut, Signer<'info>]`
  - `system_program`: `Program<'info, System>`

#### `transfer_resource_with_provenance(sequence_number: u64, new_owner_identity: Pubkey, tx_signature: [u8; 64], biometric_signature_proof: [u8; 32], memo: [u8; 64])`
Atomically mutates the `Resource.owner` field while initializing the `OwnershipRecord` PDA in the exact same transaction, preventing orphan transfers or out-of-order provenance gaps.

---

### 2.3 Teams & Custom Roles Engine

#### `create_custom_role(role_id: u8, name: [u8; 32], permissions: u64)`
Creates an enterprise custom role with an arbitrary 64-bit permission bitmask.
- **Seeds**: `[b"custom-role", organization.key().as_ref(), &[role_id]]`
- **Permissions**: Requires `MANAGE_ROLES` (`0x10`) authority or organization root admin.

#### `create_team(team_id: u8, name: [u8; 32])`
Instantiates a new workgroup/team under the organization.
- **Seeds**: `[b"team", organization.key().as_ref(), &[team_id]]`

#### `assign_team_roles(team_id: u8, role_ids: Vec<u8>)`
Assigns up to 8 custom role IDs to a team. Any verified member of the team automatically inherits the combined bitwise union (`OR`) of all assigned roles' permissions.

#### `add_team_member(team_id: u8, member_identity: Pubkey)`
Enrolls an identity PDA into the team.
- **Seeds**: `[b"team-member", team.key().as_ref(), member_identity.as_ref()]`

#### `remove_team_member(team_id: u8, member_identity: Pubkey)`
Closes the `TeamMember` PDA, instantly revoking inherited team permissions.

---

### 2.4 Identity Guardian Key Recovery

#### `configure_identity_recovery(guardians: Vec<Pubkey>, threshold: u8)`
Registers a $K$-of-$N$ guardian threshold configuration for an Identity PDA.
- **Seeds**: `[b"recovery", identity.key().as_ref()]`
- **Constraints**: Threshold must satisfy $1 \le \text{threshold} \le N \le 5$.

#### `initiate_identity_recovery(proposed_controller: Pubkey)`
Triggered by any designated guardian when a user's physical device or Ed25519 key is lost. Sets `recovery_in_progress = true`.

#### `approve_identity_recovery()`
Signed by each guardian to cast their cryptographic approval for the proposed replacement controller key.

#### `execute_identity_recovery()`
Finalizes the recovery once `approval_count >= threshold`:
- Updates `Identity.controller = proposed_controller`.
- Clears the active recovery state.
- Preserves the user's `Identity` PDA address, access grants, and owned resource PDAs intact.

---

### 2.5 Proof of Authority (PoA) Consensus

#### `initialize_poa(authorities: Vec<Pubkey>, threshold: u8)`
Initializes the $M$-of-$N$ multi-sig consensus module.
- **Seeds**: `[b"poa-config", organization.key().as_ref()]`

#### `create_proposal(proposal_id: u64, title: String, description: String, action_type: u8, target_account: Pubkey)`
Creates a governance proposal for critical or destructive organization actions.

#### `vote_proposal(proposal_id: u64, approve: bool)`
Cast an authority vote. Once approval threshold is reached, sets `proposal.executed = false` and `status = Approved`.

#### `execute_proposal(proposal_id: u64)`
Executes the approved multi-sig proposal on-chain.

---

## 3. On-Chain Error Codes

| Error Code | Hex | Message |
| :--- | :--- | :--- |
| `NotAuthorized` | `0x1770` | Caller does not possess the required permission bit. |
| `IdentityRevoked` | `0x1771` | Identity PDA is in revoked status. |
| `InvalidSequenceNumber` | `0x1772` | Provenance sequence number does not match expected increment. |
| `OwnerMismatch` | `0x1773` | Specified previous owner does not match current asset owner. |
| `TeamRoleLimitExceeded` | `0x1774` | Cannot assign more than 8 custom roles to a single team. |
| `GuardianThresholdInvalid`| `0x1775` | Quorum threshold exceeds registered guardian count. |
| `RecoveryNotInitiated` | `0x1776` | No active recovery proposal found for this identity. |
| `ThresholdNotMet` | `0x1777` | Insufficient guardian approvals to execute key rotation. |
| `PoAQuorumNotReached` | `0x1778` | Proposal has not received required multi-sig votes. |
| `ProposalExpired` | `0x1779` | Voting period for proposal has lapsed. |
