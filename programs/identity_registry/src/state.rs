use anchor_lang::prelude::*;

// Permission bitmasks
pub const CREATE_RESOURCE: u64   = 1 << 0;
pub const ASSIGN_RESOURCE: u64   = 1 << 1;
pub const TRANSFER_RESOURCE: u64 = 1 << 2;
pub const REVOKE_RESOURCE: u64   = 1 << 3;
pub const MANAGE_ROLES: u64      = 1 << 4;
pub const VERIFY: u64            = 1 << 5;

// Status constants
pub const STATUS_ACTIVE: u8 = 1;
pub const STATUS_REVOKED: u8 = 2;
pub const STATUS_SUSPENDED: u8 = 3;

// Predefined Role IDs
pub const ROLE_ADMIN: u8 = 1;
pub const ROLE_ASSET_MANAGER: u8 = 2;
pub const ROLE_AUDITOR: u8 = 3;

#[account]
#[derive(InitSpace)]
pub struct Organization {
    pub authority: Pubkey,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct Identity {
    pub controller: Pubkey,
    pub status: u8,
    pub created_at: i64,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct Role {
    pub organization: Pubkey,
    pub role_id: u8,
    pub permissions: u64,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct Resource {
    pub organization: Pubkey,
    pub resource_id: u64,
    pub owner: Pubkey, // Identity PDA
    pub resource_type: u8,
    pub status: u8,
    pub created_at: i64,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct AccessGrant {
    pub identity: Pubkey,
    pub resource: Pubkey,
    pub role: Pubkey,
    pub active: bool,
    pub expires_at: i64,
    pub bump: u8,
}

// ----------------------------------------------------------------------------
// Proof of Authority (PoA) Consensus State & Constants
// ----------------------------------------------------------------------------

pub const MAX_AUTHORITIES: usize = 7;

// Action types for Consensus Proposals
pub const ACTION_ASSIGN_ROLE: u8          = 1;
pub const ACTION_REVOKE_ROLE: u8          = 2;
pub const ACTION_REVOKE_RESOURCE: u8      = 3;
pub const ACTION_ROTATE_QUORUM: u8        = 4;
pub const ACTION_SET_IDENTITY_STATUS: u8  = 5;

// Proposal statuses
pub const PROPOSAL_PENDING: u8  = 0;
pub const PROPOSAL_APPROVED: u8 = 1;
pub const PROPOSAL_EXECUTED: u8 = 2;
pub const PROPOSAL_REJECTED: u8 = 3;

#[account]
#[derive(InitSpace)]
pub struct AuthorityQuorum {
    pub organization: Pubkey,
    pub threshold: u8,
    pub authorities_count: u8,
    pub authorities: [Pubkey; MAX_AUTHORITIES],
    pub proposal_count: u64,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct ConsensusProposal {
    pub organization: Pubkey,
    pub proposal_id: u64,
    pub proposer: Pubkey,
    pub action_type: u8,
    pub target: Pubkey,
    pub extra_data: [u8; 32],
    pub approvals_mask: u8,
    pub approval_count: u8,
    pub status: u8,
    pub created_at: i64,
    pub execution_timelock: i64,
    pub bump: u8,
}

// ----------------------------------------------------------------------------
// Asset Ownership Provenance State
// ----------------------------------------------------------------------------

pub const TRANSFER_TYPE_MINT: u8     = 0;
pub const TRANSFER_TYPE_TRANSFER: u8 = 1;
pub const TRANSFER_TYPE_REVOKE: u8   = 2;
pub const TRANSFER_TYPE_RECOVERY: u8 = 3;

#[account]
#[derive(InitSpace)]
pub struct OwnershipRecord {
    pub resource: Pubkey,
    pub sequence: u32,
    pub previous_owner: Pubkey,
    pub new_owner: Pubkey,
    pub transferred_by: Pubkey,
    pub timestamp: i64,
    pub transfer_type: u8,
    pub version: u8,
    pub reserved: [u8; 16],
    pub bump: u8,
}

// ----------------------------------------------------------------------------
// Custom Roles & Teams Architecture
// ----------------------------------------------------------------------------

#[account]
#[derive(InitSpace)]
pub struct CustomRole {
    pub organization: Pubkey,
    pub role_id: u16,
    pub name: [u8; 32],
    pub permissions: u64,
    pub version: u8,
    pub reserved: [u8; 32],
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct Team {
    pub organization: Pubkey,
    pub team_id: u32,
    pub name: [u8; 32],
    pub assigned_roles_mask: u64,
    pub member_count: u32,
    pub version: u8,
    pub reserved: [u8; 32],
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct TeamMember {
    pub team: Pubkey,
    pub identity: Pubkey,
    pub joined_at: i64,
    pub bump: u8,
}

// ----------------------------------------------------------------------------
// Identity Key Recovery Protocol (Mitigating Key Loss Risk)
// ----------------------------------------------------------------------------

pub const MAX_GUARDIANS: usize = 3;

#[account]
#[derive(InitSpace)]
pub struct IdentityRecovery {
    pub identity: Pubkey,
    pub guardians: [Pubkey; MAX_GUARDIANS],
    pub guardians_count: u8,
    pub threshold: u8,
    pub recovery_in_progress: bool,
    pub proposed_new_controller: Pubkey,
    pub approvals_mask: u8,
    pub version: u8,
    pub reserved: [u8; 16],
    pub bump: u8,
}

