use anchor_lang::prelude::*;

pub mod state;
pub mod errors;
pub mod events;
pub mod authorization;
pub mod instructions;

use instructions::*;

declare_id!("FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M");

#[program]
pub mod identity_registry {
    use super::*;

    /// Initialize the singleton Organization PDA.
    pub fn initialize_organization(ctx: Context<InitializeOrganization>) -> Result<()> {
        handler_initialize_organization(ctx)
    }

    /// Create a self-sovereign Identity PDA controlled by the user's cryptographic key.
    pub fn create_identity(ctx: Context<CreateIdentity>) -> Result<()> {
        handler_create_identity(ctx)
    }

    /// Create an RBAC Role PDA with bitmask permissions.
    pub fn create_role(
        ctx: Context<CreateRole>,
        role_id: u8,
        permissions: u64,
    ) -> Result<()> {
        handler_create_role(ctx, role_id, permissions)
    }

    /// Assign an organization-level Role to an Identity PDA.
    pub fn assign_role(ctx: Context<AssignRole>, expires_at: i64) -> Result<()> {
        handler_assign_role(ctx, expires_at)
    }

    /// Revoke an organization-level Role from an Identity PDA.
    pub fn revoke_role(ctx: Context<RevokeRole>) -> Result<()> {
        handler_revoke_role(ctx)
    }

    /// Create a custom PDA digital asset/resource owned and controlled by the program.
    pub fn create_resource(
        ctx: Context<CreateResource>,
        resource_id: u64,
        resource_type: u8,
    ) -> Result<()> {
        handler_create_resource(ctx, resource_id, resource_type)
    }

    /// Assign ownership of a Resource PDA to an Identity PDA.
    pub fn assign_resource(ctx: Context<AssignResource>) -> Result<()> {
        handler_assign_resource(ctx)
    }

    /// Transfer ownership of a Resource PDA from current owner to new owner.
    pub fn transfer_resource(ctx: Context<TransferResource>) -> Result<()> {
        handler_transfer_resource(ctx)
    }

    /// Revoke a Resource PDA.
    pub fn revoke_resource(ctx: Context<RevokeResource>) -> Result<()> {
        handler_revoke_resource(ctx)
    }

    /// Grant resource-level access to an Identity PDA with a specific Role.
    pub fn grant_access(ctx: Context<GrantAccess>, expires_at: i64) -> Result<()> {
        handler_grant_access(ctx, expires_at)
    }

    /// Revoke resource-level access from an Identity PDA.
    pub fn revoke_access(ctx: Context<RevokeAccess>) -> Result<()> {
        handler_revoke_access(ctx)
    }

    /// Verify that an Identity holds an active, non-expired AccessGrant with required permission.
    pub fn verify_permission(
        ctx: Context<VerifyPermission>,
        required_permission: u64,
    ) -> Result<()> {
        handler_verify_permission(ctx, required_permission)
    }
}
