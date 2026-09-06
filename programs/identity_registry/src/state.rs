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
