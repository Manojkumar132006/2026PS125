use anchor_lang::prelude::*;
use crate::state::*;
use crate::errors::RegistryError;
use crate::events::*;
use crate::authorization::require_permission;

// ----------------------------------------------------------------------------
// Instruction Contexts
// ----------------------------------------------------------------------------

#[derive(Accounts)]
pub struct InitializeOrganization<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + Organization::INIT_SPACE,
        seeds = [b"organization"],
        bump
    )]
    pub organization: Account<'info, Organization>,
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct CreateIdentity<'info> {
    #[account(
        init,
        payer = payer,
        space = 8 + Identity::INIT_SPACE,
        seeds = [b"identity", controller.key().as_ref()],
        bump
    )]
    pub identity: Account<'info, Identity>,
    pub controller: Signer<'info>,
    #[account(mut)]
    pub payer: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(role_id: u8)]
pub struct CreateRole<'info> {
    #[account(
        init,
        payer = payer,
        space = 8 + Role::INIT_SPACE,
        seeds = [b"role", organization.key().as_ref(), &[role_id]],
        bump
    )]
    pub role: Account<'info, Role>,
    pub organization: Account<'info, Organization>,
    #[account(
        mut,
        constraint = authority.key() == organization.authority @ RegistryError::InvalidAuthority
    )]
    pub authority: Signer<'info>,
    #[account(mut)]
    pub payer: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct AssignRole<'info> {
    #[account(
        init_if_needed,
        payer = payer,
        space = 8 + AccessGrant::INIT_SPACE,
        seeds = [
            b"grant",
            identity.key().as_ref(),
            organization.key().as_ref(),
            role.key().as_ref()
        ],
        bump
    )]
    pub grant: Account<'info, AccessGrant>,
    pub organization: Account<'info, Organization>,
    pub identity: Account<'info, Identity>,
    pub role: Account<'info, Role>,
    #[account(
        constraint = authority.key() == organization.authority @ RegistryError::InvalidAuthority
    )]
    pub authority: Signer<'info>,
    #[account(mut)]
    pub payer: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct RevokeRole<'info> {
    #[account(
        mut,
        seeds = [
            b"grant",
            identity.key().as_ref(),
            organization.key().as_ref(),
            role.key().as_ref()
        ],
        bump = grant.bump
    )]
    pub grant: Account<'info, AccessGrant>,
    pub organization: Account<'info, Organization>,
    pub identity: Account<'info, Identity>,
    pub role: Account<'info, Role>,
    #[account(
        constraint = authority.key() == organization.authority @ RegistryError::InvalidAuthority
    )]
    pub authority: Signer<'info>,
}

#[derive(Accounts)]
#[instruction(resource_id: u64)]
pub struct CreateResource<'info> {
    #[account(
        init,
        payer = payer,
        space = 8 + Resource::INIT_SPACE,
        seeds = [b"resource", organization.key().as_ref(), &resource_id.to_le_bytes()],
        bump
    )]
    pub resource: Account<'info, Resource>,
    pub organization: Account<'info, Organization>,
    pub creator_identity: Account<'info, Identity>,
    pub controller: Signer<'info>,
    pub grant: Account<'info, AccessGrant>,
    pub role: Account<'info, Role>,
    #[account(mut)]
    pub payer: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct AssignResource<'info> {
    #[account(
        mut,
        seeds = [b"resource", organization.key().as_ref(), &resource.resource_id.to_le_bytes()],
        bump = resource.bump
    )]
    pub resource: Account<'info, Resource>,
    pub organization: Account<'info, Organization>,
    pub caller_identity: Account<'info, Identity>,
    pub controller: Signer<'info>,
    pub grant: Account<'info, AccessGrant>,
    pub role: Account<'info, Role>,
    pub new_owner: Account<'info, Identity>,
}

#[derive(Accounts)]
pub struct TransferResource<'info> {
    #[account(
        mut,
        seeds = [b"resource", organization.key().as_ref(), &resource.resource_id.to_le_bytes()],
        bump = resource.bump
    )]
    pub resource: Account<'info, Resource>,
    pub organization: Account<'info, Organization>,
    pub current_owner: Account<'info, Identity>,
    pub controller: Signer<'info>,
    pub new_owner: Account<'info, Identity>,
}

#[derive(Accounts)]
pub struct RevokeResource<'info> {
    #[account(
        mut,
        seeds = [b"resource", organization.key().as_ref(), &resource.resource_id.to_le_bytes()],
        bump = resource.bump
    )]
    pub resource: Account<'info, Resource>,
    pub organization: Account<'info, Organization>,
    pub caller_identity: Account<'info, Identity>,
    pub controller: Signer<'info>,
    pub grant: Account<'info, AccessGrant>,
    pub role: Account<'info, Role>,
}

#[derive(Accounts)]
pub struct GrantAccess<'info> {
    #[account(
        init_if_needed,
        payer = payer,
        space = 8 + AccessGrant::INIT_SPACE,
        seeds = [
            b"grant",
            target_identity.key().as_ref(),
            resource.key().as_ref(),
            role.key().as_ref()
        ],
        bump
    )]
    pub grant: Account<'info, AccessGrant>,
    pub resource: Account<'info, Resource>,
    pub owner_identity: Account<'info, Identity>,
    pub controller: Signer<'info>,
    pub target_identity: Account<'info, Identity>,
    pub role: Account<'info, Role>,
    #[account(mut)]
    pub payer: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct RevokeAccess<'info> {
    #[account(
        mut,
        seeds = [
            b"grant",
            target_identity.key().as_ref(),
            resource.key().as_ref(),
            role.key().as_ref()
        ],
        bump = grant.bump
    )]
    pub grant: Account<'info, AccessGrant>,
    pub resource: Account<'info, Resource>,
    pub owner_identity: Account<'info, Identity>,
    pub controller: Signer<'info>,
    pub target_identity: Account<'info, Identity>,
    pub role: Account<'info, Role>,
}

#[derive(Accounts)]
pub struct VerifyPermission<'info> {
    pub resource: Account<'info, Resource>,
    pub identity: Account<'info, Identity>,
    pub controller: Signer<'info>,
    pub grant: Account<'info, AccessGrant>,
    pub role: Account<'info, Role>,
}

// ----------------------------------------------------------------------------
// Instruction Handlers
// ----------------------------------------------------------------------------

pub fn handler_initialize_organization(ctx: Context<InitializeOrganization>) -> Result<()> {
    let org = &mut ctx.accounts.organization;
    org.authority = ctx.accounts.authority.key();
    org.bump = ctx.bumps.organization;
    Ok(())
}

pub fn handler_create_identity(ctx: Context<CreateIdentity>) -> Result<()> {
    let identity = &mut ctx.accounts.identity;
    let clock = Clock::get()?;
    identity.controller = ctx.accounts.controller.key();
    identity.status = STATUS_ACTIVE;
    identity.created_at = clock.unix_timestamp;
    identity.bump = ctx.bumps.identity;

    emit!(IdentityCreated {
        identity: identity.key(),
        controller: identity.controller,
        created_at: identity.created_at,
    });

    Ok(())
}

pub fn handler_create_role(
    ctx: Context<CreateRole>,
    role_id: u8,
    permissions: u64,
) -> Result<()> {
    let role = &mut ctx.accounts.role;
    role.organization = ctx.accounts.organization.key();
    role.role_id = role_id;
    role.permissions = permissions;
    role.bump = ctx.bumps.role;

    emit!(RoleCreated {
        organization: role.organization,
        role: role.key(),
        role_id,
        permissions,
    });

    Ok(())
}

pub fn handler_assign_role(ctx: Context<AssignRole>, expires_at: i64) -> Result<()> {
    let grant = &mut ctx.accounts.grant;
    grant.identity = ctx.accounts.identity.key();
    grant.resource = ctx.accounts.organization.key();
    grant.role = ctx.accounts.role.key();
    grant.active = true;
    grant.expires_at = expires_at;
    grant.bump = ctx.bumps.grant;

    emit!(RoleAssigned {
        organization: ctx.accounts.organization.key(),
        identity: ctx.accounts.identity.key(),
        role: ctx.accounts.role.key(),
    });

    Ok(())
}

pub fn handler_revoke_role(ctx: Context<RevokeRole>) -> Result<()> {
    let grant = &mut ctx.accounts.grant;
    grant.active = false;

    emit!(RoleRevoked {
        organization: ctx.accounts.organization.key(),
        identity: ctx.accounts.identity.key(),
        role: ctx.accounts.role.key(),
    });

    Ok(())
}

pub fn handler_create_resource(
    ctx: Context<CreateResource>,
    resource_id: u64,
    resource_type: u8,
) -> Result<()> {
    let clock = Clock::get()?;
    require_permission(
        &ctx.accounts.creator_identity,
        &ctx.accounts.controller,
        &ctx.accounts.organization.key(),
        &ctx.accounts.grant,
        &ctx.accounts.role,
        CREATE_RESOURCE,
        clock.unix_timestamp,
    )?;

    let resource = &mut ctx.accounts.resource;
    resource.organization = ctx.accounts.organization.key();
    resource.resource_id = resource_id;
    resource.owner = ctx.accounts.creator_identity.key();
    resource.resource_type = resource_type;
    resource.status = STATUS_ACTIVE;
    resource.created_at = clock.unix_timestamp;
    resource.bump = ctx.bumps.resource;

    emit!(ResourceCreated {
        organization: resource.organization,
        resource: resource.key(),
        resource_id,
        owner: resource.owner,
        resource_type,
        created_at: resource.created_at,
    });

    Ok(())
}

pub fn handler_assign_resource(ctx: Context<AssignResource>) -> Result<()> {
    let clock = Clock::get()?;
    let resource = &mut ctx.accounts.resource;

    require!(resource.status == STATUS_ACTIVE, RegistryError::ResourceRevoked);

    require_permission(
        &ctx.accounts.caller_identity,
        &ctx.accounts.controller,
        &ctx.accounts.organization.key(),
        &ctx.accounts.grant,
        &ctx.accounts.role,
        ASSIGN_RESOURCE,
        clock.unix_timestamp,
    )?;

    let previous_owner = resource.owner;
    resource.owner = ctx.accounts.new_owner.key();

    emit!(ResourceAssigned {
        resource: resource.key(),
        previous_owner,
        new_owner: resource.owner,
    });

    Ok(())
}

pub fn handler_transfer_resource(ctx: Context<TransferResource>) -> Result<()> {
    let resource = &mut ctx.accounts.resource;

    require!(resource.status == STATUS_ACTIVE, RegistryError::ResourceRevoked);
    require_keys_eq!(resource.owner, ctx.accounts.current_owner.key(), RegistryError::NotResourceOwner);
    require_keys_eq!(ctx.accounts.current_owner.controller, ctx.accounts.controller.key(), RegistryError::IdentityMismatch);
    require!(ctx.accounts.current_owner.status == STATUS_ACTIVE, RegistryError::IdentitySuspended);

    let previous_owner = resource.owner;
    resource.owner = ctx.accounts.new_owner.key();

    emit!(ResourceTransferred {
        resource: resource.key(),
        previous_owner,
        new_owner: resource.owner,
    });

    Ok(())
}

pub fn handler_revoke_resource(ctx: Context<RevokeResource>) -> Result<()> {
    let clock = Clock::get()?;
    let resource = &mut ctx.accounts.resource;

    require!(resource.status == STATUS_ACTIVE, RegistryError::ResourceRevoked);

    require_permission(
        &ctx.accounts.caller_identity,
        &ctx.accounts.controller,
        &ctx.accounts.organization.key(),
        &ctx.accounts.grant,
        &ctx.accounts.role,
        REVOKE_RESOURCE,
        clock.unix_timestamp,
    )?;

    resource.status = STATUS_REVOKED;

    emit!(ResourceRevoked {
        resource: resource.key(),
        revoked_by: ctx.accounts.caller_identity.key(),
    });

    Ok(())
}

pub fn handler_grant_access(ctx: Context<GrantAccess>, expires_at: i64) -> Result<()> {
    let resource = &ctx.accounts.resource;

    require!(resource.status == STATUS_ACTIVE, RegistryError::ResourceRevoked);
    require_keys_eq!(resource.owner, ctx.accounts.owner_identity.key(), RegistryError::NotResourceOwner);
    require_keys_eq!(ctx.accounts.owner_identity.controller, ctx.accounts.controller.key(), RegistryError::IdentityMismatch);
    require!(ctx.accounts.owner_identity.status == STATUS_ACTIVE, RegistryError::IdentitySuspended);

    let grant = &mut ctx.accounts.grant;
    grant.identity = ctx.accounts.target_identity.key();
    grant.resource = resource.key();
    grant.role = ctx.accounts.role.key();
    grant.active = true;
    grant.expires_at = expires_at;
    grant.bump = ctx.bumps.grant;

    emit!(AccessGranted {
        resource: grant.resource,
        identity: grant.identity,
        role: grant.role,
        expires_at,
    });

    Ok(())
}

pub fn handler_revoke_access(ctx: Context<RevokeAccess>) -> Result<()> {
    let resource = &ctx.accounts.resource;

    require!(resource.status == STATUS_ACTIVE, RegistryError::ResourceRevoked);
    require_keys_eq!(resource.owner, ctx.accounts.owner_identity.key(), RegistryError::NotResourceOwner);
    require_keys_eq!(ctx.accounts.owner_identity.controller, ctx.accounts.controller.key(), RegistryError::IdentityMismatch);
    require!(ctx.accounts.owner_identity.status == STATUS_ACTIVE, RegistryError::IdentitySuspended);

    let grant = &mut ctx.accounts.grant;
    grant.active = false;

    emit!(AccessRevoked {
        resource: grant.resource,
        identity: grant.identity,
        role: grant.role,
    });

    Ok(())
}

pub fn handler_verify_permission(
    ctx: Context<VerifyPermission>,
    required_permission: u64,
) -> Result<()> {
    let clock = Clock::get()?;
    let resource = &ctx.accounts.resource;

    require!(resource.status == STATUS_ACTIVE, RegistryError::ResourceRevoked);

    require_permission(
        &ctx.accounts.identity,
        &ctx.accounts.controller,
        &resource.key(),
        &ctx.accounts.grant,
        &ctx.accounts.role,
        required_permission,
        clock.unix_timestamp,
    )?;

    emit!(PermissionVerified {
        identity: ctx.accounts.identity.key(),
        resource: resource.key(),
        role: ctx.accounts.role.key(),
        permission: required_permission,
    });

    Ok(())
}
