use anchor_lang::prelude::*;

#[error_code]
pub enum RegistryError {
    #[msg("Signer is not authorized to perform this operation")]
    Unauthorized,

    #[msg("Identity controller does not match signer")]
    IdentityMismatch,

    #[msg("Identity is not active")]
    IdentitySuspended,

    #[msg("Access grant is inactive")]
    GrantInactive,

    #[msg("Access grant has expired")]
    GrantExpired,

    #[msg("Role lacks the required permission")]
    PermissionDenied,

    #[msg("Resource has been revoked and cannot be modified or accessed")]
    ResourceRevoked,

    #[msg("Caller is not the owner of the resource")]
    NotResourceOwner,

    #[msg("Invalid organization authority")]
    InvalidAuthority,

    #[msg("Invalid resource status")]
    InvalidResourceStatus,
}
