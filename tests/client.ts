import * as anchor from "@coral-xyz/anchor";
import { Program, BN } from "@coral-xyz/anchor";
import { PublicKey, Keypair, Transaction, sendAndConfirmTransaction } from "@solana/web3.js";
import { IdentityRegistry } from "../target/types/identity_registry";

export const PERMISSIONS = {
  CREATE_RESOURCE: new BN(1).shln(0),   // 1
  ASSIGN_RESOURCE: new BN(1).shln(1),   // 2
  TRANSFER_RESOURCE: new BN(1).shln(2), // 4
  REVOKE_RESOURCE: new BN(1).shln(3),   // 8
  MANAGE_ROLES: new BN(1).shln(4),      // 16
  VERIFY: new BN(1).shln(5),            // 32
};

export const ROLE_IDS = {
  ADMIN: 1,
  ASSET_MANAGER: 2,
  AUDITOR: 3,
};

export const ACTION_TYPES = {
  ASSIGN_ROLE: 1,
  REVOKE_ROLE: 2,
  REVOKE_RESOURCE: 3,
  ROTATE_QUORUM: 4,
  SET_IDENTITY_STATUS: 5,
};

export const PROPOSAL_STATUS = {
  PENDING: 0,
  APPROVED: 1,
  EXECUTED: 2,
  REJECTED: 3,
};

export class IdentityRegistryClient {
  program: Program<IdentityRegistry>;
  provider: anchor.AnchorProvider;

  constructor(program: Program<IdentityRegistry>) {
    this.program = program;
    this.provider = program.provider as anchor.AnchorProvider;
  }

  // PDA Derivations
  getOrganizationPda(): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("organization")],
      this.program.programId
    );
  }

  getIdentityPda(controller: PublicKey): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("identity"), controller.toBuffer()],
      this.program.programId
    );
  }

  getRolePda(organization: PublicKey, roleId: number): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("role"), organization.toBuffer(), Buffer.from([roleId])],
      this.program.programId
    );
  }

  getResourcePda(organization: PublicKey, resourceId: BN): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("resource"), organization.toBuffer(), resourceId.toArrayLike(Buffer, "le", 8)],
      this.program.programId
    );
  }

  getGrantPda(identity: PublicKey, resource: PublicKey, role: PublicKey): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("grant"), identity.toBuffer(), resource.toBuffer(), role.toBuffer()],
      this.program.programId
    );
  }

  getQuorumPda(organization: PublicKey): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("quorum"), organization.toBuffer()],
      this.program.programId
    );
  }

  getProposalPda(organization: PublicKey, proposalId: BN): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("proposal"), organization.toBuffer(), proposalId.toArrayLike(Buffer, "le", 8)],
      this.program.programId
    );
  }

  getOwnershipRecordPda(resource: PublicKey, sequence: number): [PublicKey, number] {
    const seqBuf = Buffer.alloc(4);
    seqBuf.writeUInt32LE(sequence);
    return PublicKey.findProgramAddressSync(
      [Buffer.from("provenance"), resource.toBuffer(), seqBuf],
      this.program.programId
    );
  }

  getCustomRolePda(organization: PublicKey, roleId: number): [PublicKey, number] {
    const roleBuf = Buffer.alloc(2);
    roleBuf.writeUInt16LE(roleId);
    return PublicKey.findProgramAddressSync(
      [Buffer.from("custom_role"), organization.toBuffer(), roleBuf],
      this.program.programId
    );
  }

  getTeamPda(organization: PublicKey, teamId: number): [PublicKey, number] {
    const teamBuf = Buffer.alloc(4);
    teamBuf.writeUInt32LE(teamId);
    return PublicKey.findProgramAddressSync(
      [Buffer.from("team"), organization.toBuffer(), teamBuf],
      this.program.programId
    );
  }

  getTeamMemberPda(team: PublicKey, identity: PublicKey): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("team_member"), team.toBuffer(), identity.toBuffer()],
      this.program.programId
    );
  }

  getIdentityRecoveryPda(identity: PublicKey): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("recovery"), identity.toBuffer()],
      this.program.programId
    );
  }

  // Sponsored Transaction Helper
  // Sends a transaction where user signs as controller (proving authorization)
  // and sponsor signs as feePayer (covering SOL transaction fees & rent)
  async sendSponsoredTransaction(
    instructions: anchor.web3.TransactionInstruction[],
    userSigners: Keypair[],
    sponsor: Keypair
  ): Promise<string> {
    const tx = new Transaction();
    instructions.forEach((ix) => tx.add(ix));

    const latestBlockhash = await this.provider.connection.getLatestBlockhash("confirmed");
    tx.recentBlockhash = latestBlockhash.blockhash;
    tx.feePayer = sponsor.publicKey;

    // Both user and sponsor sign
    const signers = [sponsor, ...userSigners];
    return await sendAndConfirmTransaction(
      this.provider.connection,
      tx,
      signers,
      { commitment: "confirmed" }
    );
  }
}
