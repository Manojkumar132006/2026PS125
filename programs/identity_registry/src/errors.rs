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

    #[msg("Signer is not an authority in the organization's quorum")]
    NotAnAuthority,

    #[msg("Authority has already voted on this proposal")]
    ProposalAlreadyVoted,

    #[msg("Proposal has already been executed or rejected")]
    ProposalClosed,

    #[msg("Proposal has not reached the required consensus threshold")]
    QuorumNotReached,

    #[msg("Timelock has not expired yet")]
    TimelockNotExpired,

    #[msg("Invalid quorum configuration")]
    InvalidQuorumConfig,

    #[msg("Action type mismatch for proposal execution")]
    ProposalActionMismatch,

    #[msg("Target account mismatch for proposal")]
    ProposalTargetMismatch,
}
