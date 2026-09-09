use anchor_lang::prelude::*;

#[event]
pub struct IdentityCreated {
    pub identity: Pubkey,
    pub controller: Pubkey,
    pub created_at: i64,
}

#[event]
pub struct RoleCreated {
    pub organization: Pubkey,
    pub role: Pubkey,
    pub role_id: u8,
    pub permissions: u64,
}

#[event]
pub struct RoleAssigned {
    pub organization: Pubkey,
    pub identity: Pubkey,
    pub role: Pubkey,
}

#[event]
pub struct RoleRevoked {
    pub organization: Pubkey,
    pub identity: Pubkey,
    pub role: Pubkey,
}

#[event]
pub struct ResourceCreated {
    pub organization: Pubkey,
    pub resource: Pubkey,
    pub resource_id: u64,
    pub owner: Pubkey,
    pub resource_type: u8,
    pub created_at: i64,
}

#[event]
pub struct ResourceAssigned {
    pub resource: Pubkey,
    pub previous_owner: Pubkey,
    pub new_owner: Pubkey,
}

#[event]
pub struct ResourceTransferred {
    pub resource: Pubkey,
    pub previous_owner: Pubkey,
    pub new_owner: Pubkey,
}

#[event]
pub struct ResourceRevoked {
    pub resource: Pubkey,
    pub revoked_by: Pubkey,
}

#[event]
pub struct AccessGranted {
    pub resource: Pubkey,
    pub identity: Pubkey,
    pub role: Pubkey,
    pub expires_at: i64,
}

#[event]
pub struct AccessRevoked {
    pub resource: Pubkey,
    pub identity: Pubkey,
    pub role: Pubkey,
}

#[event]
pub struct PermissionVerified {
    pub identity: Pubkey,
    pub resource: Pubkey,
    pub role: Pubkey,
    pub permission: u64,
}

#[event]
pub struct QuorumInitialized {
    pub organization: Pubkey,
    pub threshold: u8,
    pub authorities_count: u8,
}

#[event]
pub struct ProposalCreated {
    pub organization: Pubkey,
    pub proposal_id: u64,
    pub proposer: Pubkey,
    pub action_type: u8,
    pub target: Pubkey,
}

#[event]
pub struct ProposalApproved {
    pub organization: Pubkey,
    pub proposal_id: u64,
    pub authority: Pubkey,
    pub approval_count: u8,
}

#[event]
pub struct ProposalExecuted {
    pub organization: Pubkey,
    pub proposal_id: u64,
    pub action_type: u8,
    pub target: Pubkey,
}

#[event]
pub struct ProposalRejected {
    pub organization: Pubkey,
    pub proposal_id: u64,
    pub authority: Pubkey,
}

