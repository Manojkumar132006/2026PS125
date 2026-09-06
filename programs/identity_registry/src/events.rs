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
