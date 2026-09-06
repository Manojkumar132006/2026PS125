use anchor_lang::prelude::*;

declare_id!("FPMb6CKZ6hnpjSZ1WgkVToZAExe5hisjJ3VjYyDnaZ6M");

#[program]
pub mod contracts {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}
