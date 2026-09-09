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

    #[msg("Team or role name exceeds maximum length of 32 bytes")]
    NameTooLong,

    #[msg("Identity is already a member of this team")]
    MemberAlreadyInTeam,

    #[msg("Identity is not a member of this team")]
    MemberNotInTeam,

    #[msg("Key recovery is not configured for this identity")]
    RecoveryNotConfigured,

    #[msg("Invalid recovery threshold: must be > 0 and <= guardians count")]
    InvalidRecoveryThreshold,

    #[msg("A key recovery operation is already in progress")]
    RecoveryAlreadyInProgress,

    #[msg("No key recovery operation is currently active")]
    RecoveryNotInProgress,

    #[msg("Signer is not an authorized recovery guardian")]
    UnauthorizedGuardian,

    #[msg("Guardian has already approved this recovery")]
    GuardianAlreadyVoted,

    #[msg("Recovery approval threshold has not been reached")]
    RecoveryThresholdNotMet,

    #[msg("Ownership sequence must match current transfer count")]
    InvalidOwnershipSequence,
}
