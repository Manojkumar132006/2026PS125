use anchor_lang::prelude::*;
use crate::state::{Identity, AccessGrant, Role, STATUS_ACTIVE};
use crate::errors::RegistryError;

/// Reusable trustless authorization function enforced on-chain.
/// Verifies:
/// 1. Identity controller signed the transaction
/// 2. Identity is ACTIVE
/// 3. AccessGrant belongs to (identity, resource, role)
/// 4. AccessGrant is currently active
/// 5. AccessGrant has not expired
/// 6. Role contains the required permission bitmask
pub fn require_permission(
    identity: &Account<Identity>,
    controller: &Signer,
    resource: &Pubkey,
    grant: &Account<AccessGrant>,
    role: &Account<Role>,
    required_permission: u64,
    current_time: i64,
) -> Result<()> {
    // 1. Verify controller signature matches identity controller
    require_keys_eq!(identity.controller, controller.key(), RegistryError::IdentityMismatch);

    // 2. Verify identity status is ACTIVE
    require!(identity.status == STATUS_ACTIVE, RegistryError::IdentitySuspended);

    // 3. Verify grant matches identity, resource, and role
    require_keys_eq!(grant.identity, identity.key(), RegistryError::Unauthorized);
    require_keys_eq!(grant.resource, *resource, RegistryError::Unauthorized);
    require_keys_eq!(grant.role, role.key(), RegistryError::Unauthorized);

    // 4. Verify grant is active
    require!(grant.active, RegistryError::GrantInactive);

    // 5. Verify grant has not expired
    if grant.expires_at > 0 {
        require!(current_time < grant.expires_at, RegistryError::GrantExpired);
    }

    // 6. Verify role contains the required permission
    require!(
        (role.permissions & required_permission) == required_permission,
        RegistryError::PermissionDenied
    );

    Ok(())
}
