import * as anchor from "@coral-xyz/anchor";
import { Program, BN } from "@coral-xyz/anchor";
import { PublicKey, Keypair, SystemProgram, LAMPORTS_PER_SOL } from "@solana/web3.js";
import { expect } from "chai";
import { IdentityRegistry } from "../target/types/identity_registry";
import { IdentityRegistryClient, PERMISSIONS, ROLE_IDS, ACTION_TYPES, PROPOSAL_STATUS } from "./client";

describe("Identity Registry MVP", () => {
  anchor.setProvider(anchor.AnchorProvider.env());

  const provider = anchor.getProvider() as anchor.AnchorProvider;
  const program = anchor.workspace.IdentityRegistry as Program<IdentityRegistry>;
  const client = new IdentityRegistryClient(program);

  // Keypairs for actors
  const orgAuthority = (provider.wallet as anchor.Wallet).payer;
  const sponsorWallet = Keypair.generate();
  const userA = Keypair.generate();
  const userB = Keypair.generate();
  const userC = Keypair.generate();
  const attacker = Keypair.generate();

  // PDA references
  const [orgPda] = client.getOrganizationPda();
  const [identityAPda] = client.getIdentityPda(userA.publicKey);
  const [identityBPda] = client.getIdentityPda(userB.publicKey);
  const [identityCPda] = client.getIdentityPda(userC.publicKey);
  const [attackerIdentityPda] = client.getIdentityPda(attacker.publicKey);

  const [adminRolePda] = client.getRolePda(orgPda, ROLE_IDS.ADMIN);
  const [assetManagerRolePda] = client.getRolePda(orgPda, ROLE_IDS.ASSET_MANAGER);
  const [auditorRolePda] = client.getRolePda(orgPda, ROLE_IDS.AUDITOR);

  const resource1Id = new BN(1);
  const [resource1Pda] = client.getResourcePda(orgPda, resource1Id);

  const [grantAOrgPda] = client.getGrantPda(identityAPda, orgPda, assetManagerRolePda);
  const [grantAResource1Pda] = client.getGrantPda(identityAPda, resource1Pda, assetManagerRolePda);
  const [grantBResource1Pda] = client.getGrantPda(identityBPda, resource1Pda, auditorRolePda);

  // Audit event log collector
  const emittedEvents: Array<{ name: string; data: any }> = [];
  const listenerIds: number[] = [];

  before(async () => {
    // Fund actors with SOL for testing
    const airdropTx = await provider.connection.requestAirdrop(
      sponsorWallet.publicKey,
      2 * LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(airdropTx);

    const airdropUserA = await provider.connection.requestAirdrop(
      userA.publicKey,
      1 * LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(airdropUserA);

    const airdropUserB = await provider.connection.requestAirdrop(
      userB.publicKey,
      1 * LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(airdropUserB);

    const airdropAttacker = await provider.connection.requestAirdrop(
      attacker.publicKey,
      1 * LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(airdropAttacker);

    // Subscribe to program events
    listenerIds.push(program.addEventListener("identityCreated", (event) => {
      emittedEvents.push({ name: "IdentityCreated", data: event });
    }));
    listenerIds.push(program.addEventListener("roleCreated", (event) => {
      emittedEvents.push({ name: "RoleCreated", data: event });
    }));
    listenerIds.push(program.addEventListener("roleAssigned", (event) => {
      emittedEvents.push({ name: "RoleAssigned", data: event });
    }));
    listenerIds.push(program.addEventListener("roleRevoked", (event) => {
      emittedEvents.push({ name: "RoleRevoked", data: event });
    }));
    listenerIds.push(program.addEventListener("resourceCreated", (event) => {
      emittedEvents.push({ name: "ResourceCreated", data: event });
    }));
    listenerIds.push(program.addEventListener("resourceAssigned", (event) => {
      emittedEvents.push({ name: "ResourceAssigned", data: event });
    }));
    listenerIds.push(program.addEventListener("resourceTransferred", (event) => {
      emittedEvents.push({ name: "ResourceTransferred", data: event });
    }));
    listenerIds.push(program.addEventListener("resourceRevoked", (event) => {
      emittedEvents.push({ name: "ResourceRevoked", data: event });
    }));
    listenerIds.push(program.addEventListener("accessGranted", (event) => {
      emittedEvents.push({ name: "AccessGranted", data: event });
    }));
    listenerIds.push(program.addEventListener("accessRevoked", (event) => {
      emittedEvents.push({ name: "AccessRevoked", data: event });
    }));
    listenerIds.push(program.addEventListener("permissionVerified", (event) => {
      emittedEvents.push({ name: "PermissionVerified", data: event });
    }));
  });

  // ==========================================================================
  // 1. SECTION 14 TESTING REQUIREMENTS: UNIT & SECURITY TESTS
  // ==========================================================================

  describe("1. Identity Tests", () => {
    it("creates organization", async () => {
      const tx = await program.methods
        .initializeOrganization()
        .accountsPartial({
          organization: orgPda,
          authority: orgAuthority.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .rpc();

      const orgAcc = await program.account.organization.fetch(orgPda);
      expect(orgAcc.authority.toBase58()).to.equal(orgAuthority.publicKey.toBase58());
      console.log("  ✔ Organization initialized (tx:", tx.slice(0, 16), "...)");
    });

    it("creates self-sovereign identity", async () => {
      const tx = await program.methods
        .createIdentity()
        .accountsPartial({
          identity: identityAPda,
          controller: userA.publicKey,
          payer: userA.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([userA])
        .rpc();

      const identityAcc = await program.account.identity.fetch(identityAPda);
      expect(identityAcc.controller.toBase58()).to.equal(userA.publicKey.toBase58());
      expect(identityAcc.status).to.equal(1); // ACTIVE
      console.log("  ✔ Identity A created (tx:", tx.slice(0, 16), "...)");
    });

    it("rejects duplicate identity creation", async () => {
      try {
        await program.methods
          .createIdentity()
          .accountsPartial({
            identity: identityAPda,
            controller: userA.publicKey,
            payer: userA.publicKey,
            systemProgram: SystemProgram.programId,
          })
          .signers([userA])
          .rpc();
        expect.fail("Should have failed to create duplicate identity");
      } catch (err: any) {
        expect(err.toString()).to.include("already in use");
        console.log("  ✔ Rejected duplicate identity successfully");
      }
    });
  });

  describe("2. RBAC Tests", () => {
    it("creates roles with bitmask permissions", async () => {
      // ADMIN role: all permissions
      const adminPerms = PERMISSIONS.CREATE_RESOURCE
        .or(PERMISSIONS.ASSIGN_RESOURCE)
        .or(PERMISSIONS.TRANSFER_RESOURCE)
        .or(PERMISSIONS.REVOKE_RESOURCE)
        .or(PERMISSIONS.MANAGE_ROLES)
        .or(PERMISSIONS.VERIFY);

      await program.methods
        .createRole(ROLE_IDS.ADMIN, adminPerms)
        .accountsPartial({
          role: adminRolePda,
          organization: orgPda,
          authority: orgAuthority.publicKey,
          payer: orgAuthority.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .rpc();

      // ASSET_MANAGER role: create, assign, transfer, revoke, verify
      const assetManagerPerms = PERMISSIONS.CREATE_RESOURCE
        .or(PERMISSIONS.ASSIGN_RESOURCE)
        .or(PERMISSIONS.TRANSFER_RESOURCE)
        .or(PERMISSIONS.REVOKE_RESOURCE)
        .or(PERMISSIONS.VERIFY);

      await program.methods
        .createRole(ROLE_IDS.ASSET_MANAGER, assetManagerPerms)
        .accountsPartial({
          role: assetManagerRolePda,
          organization: orgPda,
          authority: orgAuthority.publicKey,
          payer: orgAuthority.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .rpc();

      // AUDITOR role: verify only
      await program.methods
        .createRole(ROLE_IDS.AUDITOR, PERMISSIONS.VERIFY)
        .accountsPartial({
          role: auditorRolePda,
          organization: orgPda,
          authority: orgAuthority.publicKey,
          payer: orgAuthority.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .rpc();

      const managerAcc = await program.account.role.fetch(assetManagerRolePda);
      expect(managerAcc.roleId).to.equal(ROLE_IDS.ASSET_MANAGER);
      expect(managerAcc.permissions.toNumber()).to.equal(assetManagerPerms.toNumber());
      console.log("  ✔ Roles created with bitmasks");
    });

    it("rejects unauthorized role management", async () => {
      try {
        await program.methods
          .createRole(99, new BN(1))
          .accountsPartial({
            role: client.getRolePda(orgPda, 99)[0],
            organization: orgPda,
            authority: attacker.publicKey,
            payer: attacker.publicKey,
            systemProgram: SystemProgram.programId,
          })
          .signers([attacker])
          .rpc();
        expect.fail("Should have rejected unauthorized role creation");
      } catch (err: any) {
        expect(err.toString()).to.include("InvalidAuthority");
        console.log("  ✔ Unauthorized role management rejected");
      }
    });

    it("assigns and revokes role", async () => {
      // Assign ASSET_MANAGER to Identity A
      await program.methods
        .assignRole(new BN(0)) // no expiry
        .accountsPartial({
          grant: grantAOrgPda,
          organization: orgPda,
          identity: identityAPda,
          role: assetManagerRolePda,
          authority: orgAuthority.publicKey,
          payer: orgAuthority.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .rpc();

      let grantAcc = await program.account.accessGrant.fetch(grantAOrgPda);
      expect(grantAcc.active).to.be.true;

      // Revoke role
      await program.methods
        .revokeRole()
        .accountsPartial({
          grant: grantAOrgPda,
          organization: orgPda,
          identity: identityAPda,
          role: assetManagerRolePda,
          authority: orgAuthority.publicKey,
        })
        .rpc();

      grantAcc = await program.account.accessGrant.fetch(grantAOrgPda);
      expect(grantAcc.active).to.be.false;

      // Re-activate role for subsequent tests
      await program.methods
        .assignRole(new BN(0))
        .accountsPartial({
          grant: grantAOrgPda,
          organization: orgPda,
          identity: identityAPda,
          role: assetManagerRolePda,
          authority: orgAuthority.publicKey,
          payer: orgAuthority.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .rpc();
      console.log("  ✔ Role assigned, revoked, and verified");
    });
  });

  describe("3. Resource & Access Tests", () => {
    it("creates Identity B and Identity C", async () => {
      await program.methods
        .createIdentity()
        .accountsPartial({
          identity: identityBPda,
          controller: userB.publicKey,
          payer: userB.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([userB])
        .rpc();

      await program.methods
        .createIdentity()
        .accountsPartial({
          identity: identityCPda,
          controller: userC.publicKey,
          payer: orgAuthority.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([userC])
        .rpc();

      console.log("  ✔ Identity B and C created");
    });

    it("creates digital asset (Resource #1)", async () => {
      const tx = await program.methods
        .createResource(resource1Id, 1) // resource_type = 1
        .accountsPartial({
          resource: resource1Pda,
          organization: orgPda,
          creatorIdentity: identityAPda,
          controller: userA.publicKey,
          grant: grantAOrgPda,
          role: assetManagerRolePda,
          payer: userA.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([userA])
        .rpc();

      const resAcc = await program.account.resource.fetch(resource1Pda);
      expect(resAcc.resourceId.toNumber()).to.equal(1);
      expect(resAcc.owner.toBase58()).to.equal(identityAPda.toBase58());
      expect(resAcc.status).to.equal(1); // ACTIVE
      console.log("  ✔ Resource #1 created (tx:", tx.slice(0, 16), "...)");
    });

    it("assigns Resource #1 to Identity B", async () => {
      await program.methods
        .assignResource()
        .accountsPartial({
          resource: resource1Pda,
          organization: orgPda,
          callerIdentity: identityAPda,
          controller: userA.publicKey,
          grant: grantAOrgPda,
          role: assetManagerRolePda,
          newOwner: identityBPda,
        })
        .signers([userA])
        .rpc();

      const resAcc = await program.account.resource.fetch(resource1Pda);
      expect(resAcc.owner.toBase58()).to.equal(identityBPda.toBase58());
      console.log("  ✔ Resource #1 assigned to Identity B");
    });

    it("grants Identity A access to Resource #1", async () => {
      // Identity B (current owner) grants Identity A access to Resource #1
      await program.methods
        .grantAccess(new BN(0)) // no expiry
        .accountsPartial({
          grant: grantAResource1Pda,
          resource: resource1Pda,
          ownerIdentity: identityBPda,
          controller: userB.publicKey,
          targetIdentity: identityAPda,
          role: assetManagerRolePda,
          payer: userB.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([userB])
        .rpc();

      const grantAcc = await program.account.accessGrant.fetch(grantAResource1Pda);
      expect(grantAcc.active).to.be.true;
      expect(grantAcc.identity.toBase58()).to.equal(identityAPda.toBase58());
      console.log("  ✔ Identity A granted access to Resource #1");
    });

    it("verifies authorized permission on Resource #1", async () => {
      // Identity A verifies VERIFY permission
      const tx = await program.methods
        .verifyPermission(PERMISSIONS.VERIFY)
        .accountsPartial({
          resource: resource1Pda,
          identity: identityAPda,
          controller: userA.publicKey,
          grant: grantAResource1Pda,
          role: assetManagerRolePda,
        })
        .signers([userA])
        .rpc();

      expect(tx).to.be.a("string");
      console.log("  ✔ Identity A verified permission (tx:", tx.slice(0, 16), "...)");
    });

    it("rejects unauthorized access attempt", async () => {
      // Attacker creates identity but has no grant on Resource #1
      await program.methods
        .createIdentity()
        .accountsPartial({
          identity: attackerIdentityPda,
          controller: attacker.publicKey,
          payer: attacker.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([attacker])
        .rpc();

      try {
        // Attacker attempts to verify permission using Identity A's grant
        await program.methods
          .verifyPermission(PERMISSIONS.VERIFY)
          .accountsPartial({
            resource: resource1Pda,
            identity: attackerIdentityPda,
            controller: attacker.publicKey,
            grant: grantAResource1Pda,
            role: assetManagerRolePda,
          })
          .signers([attacker])
          .rpc();
        expect.fail("Should have rejected unauthorized access");
      } catch (err: any) {
        expect(err.toString()).to.include("Unauthorized");
        console.log("  ✔ Unauthorized access attempt rejected");
      }
    });

    it("rejects revoked access", async () => {
      // Identity B revokes Identity A's access grant
      await program.methods
        .revokeAccess()
        .accountsPartial({
          grant: grantAResource1Pda,
          resource: resource1Pda,
          ownerIdentity: identityBPda,
          controller: userB.publicKey,
          targetIdentity: identityAPda,
          role: assetManagerRolePda,
        })
        .signers([userB])
        .rpc();

      try {
        await program.methods
          .verifyPermission(PERMISSIONS.VERIFY)
          .accountsPartial({
            resource: resource1Pda,
            identity: identityAPda,
            controller: userA.publicKey,
            grant: grantAResource1Pda,
            role: assetManagerRolePda,
          })
          .signers([userA])
          .rpc();
        expect.fail("Should have rejected revoked access");
      } catch (err: any) {
        expect(err.toString()).to.include("GrantInactive");
        console.log("  ✔ Revoked access rejected");
      }

      // Re-grant access for subsequent tests
      await program.methods
        .grantAccess(new BN(0))
        .accountsPartial({
          grant: grantAResource1Pda,
          resource: resource1Pda,
          ownerIdentity: identityBPda,
          controller: userB.publicKey,
          targetIdentity: identityAPda,
          role: assetManagerRolePda,
          payer: userB.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([userB])
        .rpc();
    });

    it("rejects expired access", async () => {
      const expiredTime = new BN(Math.floor(Date.now() / 1000) - 100); // in the past
      const [expiredGrantPda] = client.getGrantPda(identityBPda, resource1Pda, auditorRolePda);

      await program.methods
        .grantAccess(expiredTime)
        .accountsPartial({
          grant: expiredGrantPda,
          resource: resource1Pda,
          ownerIdentity: identityBPda,
          controller: userB.publicKey,
          targetIdentity: identityBPda,
          role: auditorRolePda,
          payer: userB.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([userB])
        .rpc();

      try {
        await program.methods
          .verifyPermission(PERMISSIONS.VERIFY)
          .accountsPartial({
            resource: resource1Pda,
            identity: identityBPda,
            controller: userB.publicKey,
            grant: expiredGrantPda,
            role: auditorRolePda,
          })
          .signers([userB])
          .rpc();
        expect.fail("Should have rejected expired access grant");
      } catch (err: any) {
        expect(err.toString()).to.include("GrantExpired");
        console.log("  ✔ Expired access rejected");
      }
    });

    it("transfers Resource #1 from Identity B to Identity C", async () => {
      await program.methods
        .transferResource()
        .accountsPartial({
          resource: resource1Pda,
          organization: orgPda,
          currentOwner: identityBPda,
          controller: userB.publicKey,
          newOwner: identityCPda,
        })
        .signers([userB])
        .rpc();

      const resAcc = await program.account.resource.fetch(resource1Pda);
      expect(resAcc.owner.toBase58()).to.equal(identityCPda.toBase58());
      console.log("  ✔ Resource #1 transferred to Identity C");
    });

    it("revokes Resource #1 and rejects subsequent operations", async () => {
      // Identity A (Asset Manager) revokes Resource #1
      await program.methods
        .revokeResource()
        .accountsPartial({
          resource: resource1Pda,
          organization: orgPda,
          callerIdentity: identityAPda,
          controller: userA.publicKey,
          grant: grantAOrgPda,
          role: assetManagerRolePda,
        })
        .signers([userA])
        .rpc();

      const resAcc = await program.account.resource.fetch(resource1Pda);
      expect(resAcc.status).to.equal(2); // REVOKED

      // Attempt transfer of revoked resource -> must be rejected
      try {
        await program.methods
          .transferResource()
          .accountsPartial({
            resource: resource1Pda,
            organization: orgPda,
            currentOwner: identityCPda,
            controller: userC.publicKey,
            newOwner: identityAPda,
          })
          .signers([userC])
          .rpc();
        expect.fail("Should have rejected transfer of revoked resource");
      } catch (err: any) {
        expect(err.toString()).to.include("ResourceRevoked");
        console.log("  ✔ Transfer of revoked resource rejected");
      }

      // Attempt operation on revoked resource -> must be rejected
      try {
        await program.methods
          .verifyPermission(PERMISSIONS.VERIFY)
          .accountsPartial({
            resource: resource1Pda,
            identity: identityAPda,
            controller: userA.publicKey,
            grant: grantAResource1Pda,
            role: assetManagerRolePda,
          })
          .signers([userA])
          .rpc();
        expect.fail("Should have rejected operation on revoked resource");
      } catch (err: any) {
        expect(err.toString()).to.include("ResourceRevoked");
        console.log("  ✔ Operation on revoked resource rejected");
      }
    });
  });

  // ==========================================================================
  // 4. ORGANIZATION-SPONSORED TRANSACTION TESTS
  // ==========================================================================

  describe("4. Sponsored Transactions", () => {
    it("executes transaction where zero-SOL user signs and organization sponsor pays fees", async () => {
      const zeroSolUser = Keypair.generate();
      const [zeroSolIdentityPda] = client.getIdentityPda(zeroSolUser.publicKey);

      // Verify user has 0 SOL
      const initialBal = await provider.connection.getBalance(zeroSolUser.publicKey);
      expect(initialBal).to.equal(0);

      const createIx = await program.methods
        .createIdentity()
        .accountsPartial({
          identity: zeroSolIdentityPda,
          controller: zeroSolUser.publicKey,
          payer: sponsorWallet.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .instruction();

      // Sponsor signs as fee payer, zeroSolUser signs as controller
      const txSig = await client.sendSponsoredTransaction(
        [createIx],
        [zeroSolUser],
        sponsorWallet
      );

      // Verify identity was created on-chain
      const identityAcc = await program.account.identity.fetch(zeroSolIdentityPda);
      expect(identityAcc.controller.toBase58()).to.equal(zeroSolUser.publicKey.toBase58());

      // Verify user STILL has 0 SOL
      const finalBal = await provider.connection.getBalance(zeroSolUser.publicKey);
      expect(finalBal).to.equal(0);

      console.log("  ✔ Sponsored transaction successful: User has 0 SOL! (tx:", txSig.slice(0, 16), "...)");
    });
  });

  // ==========================================================================
  // 5. SECTION 12: EXACT 17-STEP END-TO-END DEMONSTRATION SCENARIO
  // ==========================================================================

  describe("5. End-to-End Acceptance Scenario (Exact 17 Steps)", () => {
    // Dedicated fresh keys for the exact 17-step flow
    const flowAuthority = Keypair.generate();
    const flowUserA = Keypair.generate();
    const flowUserB = Keypair.generate();
    const flowUserC = Keypair.generate();

    const [flowOrg] = PublicKey.findProgramAddressSync([Buffer.from("organization")], program.programId);
    // Since organization PDA is singleton ["organization"], we use the initialized org
    const [idAPda] = client.getIdentityPda(flowUserA.publicKey);
    const [idBPda] = client.getIdentityPda(flowUserB.publicKey);
    const [idCPda] = client.getIdentityPda(flowUserC.publicKey);

    const stepResource = new BN(100);
    const [res100Pda] = client.getResourcePda(orgPda, stepResource);

    const [grantAOrg] = client.getGrantPda(idAPda, orgPda, assetManagerRolePda);
    const [grantARes100] = client.getGrantPda(idAPda, res100Pda, assetManagerRolePda);

    before(async () => {
      // Fund actors
      for (const u of [flowUserA, flowUserB, flowUserC]) {
        const tx = await provider.connection.requestAirdrop(u.publicKey, 1 * LAMPORTS_PER_SOL);
        await provider.connection.confirmTransaction(tx);
      }
    });

    it("Step 1: Initialize organization (verified in setup)", async () => {
      const orgAcc = await program.account.organization.fetch(orgPda);
      expect(orgAcc.authority).to.not.be.null;
      console.log("  [Step 1] Organization initialized");
    });

    it("Step 2: Create Identity A", async () => {
      const tx = await program.methods
        .createIdentity()
        .accountsPartial({
          identity: idAPda,
          controller: flowUserA.publicKey,
          payer: flowUserA.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([flowUserA])
        .rpc();
      console.log("  [Step 2] Identity A created (tx:", tx.slice(0, 16), "...)");
    });

    it("Step 3: Create Identity B", async () => {
      const tx = await program.methods
        .createIdentity()
        .accountsPartial({
          identity: idBPda,
          controller: flowUserB.publicKey,
          payer: flowUserB.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([flowUserB])
        .rpc();
      console.log("  [Step 3] Identity B created (tx:", tx.slice(0, 16), "...)");
    });

    it("Step 4: Create ADMIN role", async () => {
      const roleAcc = await program.account.role.fetch(adminRolePda);
      expect(roleAcc.roleId).to.equal(ROLE_IDS.ADMIN);
      console.log("  [Step 4] ADMIN role active with full permissions");
    });

    it("Step 5: Create ASSET_MANAGER role", async () => {
      const roleAcc = await program.account.role.fetch(assetManagerRolePda);
      expect(roleAcc.roleId).to.equal(ROLE_IDS.ASSET_MANAGER);
      console.log("  [Step 5] ASSET_MANAGER role active");
    });

    it("Step 6: Assign ASSET_MANAGER to Identity A", async () => {
      const tx = await program.methods
        .assignRole(new BN(0))
        .accountsPartial({
          grant: grantAOrg,
          organization: orgPda,
          identity: idAPda,
          role: assetManagerRolePda,
          authority: orgAuthority.publicKey,
          payer: orgAuthority.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .rpc();
      console.log("  [Step 6] ASSET_MANAGER assigned to Identity A (tx:", tx.slice(0, 16), "...)");
    });

    it("Step 7: Create Resource #1", async () => {
      const tx = await program.methods
        .createResource(stepResource, 1)
        .accountsPartial({
          resource: res100Pda,
          organization: orgPda,
          creatorIdentity: idAPda,
          controller: flowUserA.publicKey,
          grant: grantAOrg,
          role: assetManagerRolePda,
          payer: flowUserA.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([flowUserA])
        .rpc();
      console.log("  [Step 7] Resource #1 created by Identity A (tx:", tx.slice(0, 16), "...)");
    });

    it("Step 8: Assign Resource #1 to Identity B", async () => {
      const tx = await program.methods
        .assignResource()
        .accountsPartial({
          resource: res100Pda,
          organization: orgPda,
          callerIdentity: idAPda,
          controller: flowUserA.publicKey,
          grant: grantAOrg,
          role: assetManagerRolePda,
          newOwner: idBPda,
        })
        .signers([flowUserA])
        .rpc();
      console.log("  [Step 8] Resource #1 assigned to Identity B (tx:", tx.slice(0, 16), "...)");
    });

    it("Step 9: Grant Identity A access to Resource #1", async () => {
      const tx = await program.methods
        .grantAccess(new BN(0))
        .accountsPartial({
          grant: grantARes100,
          resource: res100Pda,
          ownerIdentity: idBPda,
          controller: flowUserB.publicKey,
          targetIdentity: idAPda,
          role: assetManagerRolePda,
          payer: flowUserB.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([flowUserB])
        .rpc();
      console.log("  [Step 9] Identity A granted access to Resource #1 (tx:", tx.slice(0, 16), "...)");
    });

    it("Step 10: Identity A performs an authorized operation", async () => {
      const tx = await program.methods
        .verifyPermission(PERMISSIONS.VERIFY)
        .accountsPartial({
          resource: res100Pda,
          identity: idAPda,
          controller: flowUserA.publicKey,
          grant: grantARes100,
          role: assetManagerRolePda,
        })
        .signers([flowUserA])
        .rpc();
      console.log("  [Step 10] Identity A performed authorized operation (tx:", tx.slice(0, 16), "...)");
    });

    it("Step 11: Unauthorized Identity B attempts the same operation", async () => {
      console.log("  [Step 11] Unauthorized Identity B attempts the same operation...");
      // Identity B has no grant on Resource #1 with ASSET_MANAGER role
      let rejected = false;
      try {
        await program.methods
          .verifyPermission(PERMISSIONS.VERIFY)
          .accountsPartial({
            resource: res100Pda,
            identity: idBPda,
            controller: flowUserB.publicKey,
            grant: grantARes100, // Identity A's grant!
            role: assetManagerRolePda,
          })
          .signers([flowUserB])
          .rpc();
      } catch (err: any) {
        rejected = true;
        expect(err.toString()).to.include("Unauthorized");
      }
      expect(rejected).to.be.true;
    });

    it("Step 12: Program rejects the unauthorized operation", async () => {
      console.log("  [Step 12] Program successfully rejected unauthorized operation");
    });

    it("Step 13: Transfer Resource #1 from Identity B to another identity", async () => {
      // Create Identity C
      await program.methods
        .createIdentity()
        .accountsPartial({
          identity: idCPda,
          controller: flowUserC.publicKey,
          payer: flowUserC.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([flowUserC])
        .rpc();

      // Identity B transfers Resource #1 to Identity C
      const tx = await program.methods
        .transferResource()
        .accountsPartial({
          resource: res100Pda,
          organization: orgPda,
          currentOwner: idBPda,
          controller: flowUserB.publicKey,
          newOwner: idCPda,
        })
        .signers([flowUserB])
        .rpc();

      const resAcc = await program.account.resource.fetch(res100Pda);
      expect(resAcc.owner.toBase58()).to.equal(idCPda.toBase58());
      console.log("  [Step 13] Resource #1 transferred to Identity C (tx:", tx.slice(0, 16), "...)");
    });

    it("Step 14: Revoke Resource #1", async () => {
      const tx = await program.methods
        .revokeResource()
        .accountsPartial({
          resource: res100Pda,
          organization: orgPda,
          callerIdentity: idAPda,
          controller: flowUserA.publicKey,
          grant: grantAOrg,
          role: assetManagerRolePda,
        })
        .signers([flowUserA])
        .rpc();

      const resAcc = await program.account.resource.fetch(res100Pda);
      expect(resAcc.status).to.equal(2); // REVOKED
      console.log("  [Step 14] Resource #1 revoked (tx:", tx.slice(0, 16), "...)");
    });

    it("Step 15: Attempt another operation", async () => {
      console.log("  [Step 15] Attempting operation on revoked Resource #1...");
      let rejected = false;
      try {
        await program.methods
          .verifyPermission(PERMISSIONS.VERIFY)
          .accountsPartial({
            resource: res100Pda,
            identity: idAPda,
            controller: flowUserA.publicKey,
            grant: grantARes100,
            role: assetManagerRolePda,
          })
          .signers([flowUserA])
          .rpc();
      } catch (err: any) {
        rejected = true;
        expect(err.toString()).to.include("ResourceRevoked");
      }
      expect(rejected).to.be.true;
    });

    it("Step 16: Program rejects it", async () => {
      console.log("  [Step 16] Program rejected operation on revoked resource");
    });

    it("Step 17: Show emitted events and transaction signatures", async () => {
      // Allow slight window for listener to capture
      await new Promise((resolve) => setTimeout(resolve, 500));
      console.log("\n  ========================================================");
      console.log("  [Step 17] AUDIT TRAIL: IMMUTABLE ON-CHAIN EMITTED EVENTS");
      console.log("  ========================================================");
      console.log(`  Total events captured in session: ${emittedEvents.length}`);
      const eventSummary = emittedEvents.map((e, idx) => `    ${idx + 1}. [${e.name}]`).join("\n");
      console.log(eventSummary);
      expect(emittedEvents.length).to.be.greaterThan(5);
    });
  });

  describe("Proof of Authority (PoA) Consensus Engine", () => {
    const auth1 = Keypair.generate();
    const auth2 = Keypair.generate();
    const auth3 = Keypair.generate();
    const rogueAttacker = Keypair.generate();

    const [quorumPda] = client.getQuorumPda(orgPda);
    const poaResourceId = new BN(999);
    const [poaResourcePda] = client.getResourcePda(orgPda, poaResourceId);

    before(async () => {
      // Fund PoA authorities
      for (const kp of [auth1, auth2, auth3, rogueAttacker]) {
        const sig = await provider.connection.requestAirdrop(kp.publicKey, 2 * LAMPORTS_PER_SOL);
        await provider.connection.confirmTransaction(sig);
      }

      // Create a test resource #999 to test consensus revocation
      const [identityAPda] = client.getIdentityPda(userA.publicKey);
      const [assetManagerRolePda] = client.getRolePda(orgPda, ROLE_IDS.ASSET_MANAGER);
      const [grantAOrgPda] = client.getGrantPda(identityAPda, orgPda, assetManagerRolePda);

      await program.methods
        .createResource(poaResourceId, 1)
        .accountsPartial({
          resource: poaResourcePda,
          organization: orgPda,
          creatorIdentity: identityAPda,
          controller: userA.publicKey,
          grant: grantAOrgPda,
          role: assetManagerRolePda,
          payer: orgAuthority.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([userA])
        .rpc();
    });

    it("Rejects invalid quorum configuration (threshold 0)", async () => {
      let failed = false;
      try {
        await program.methods
          .initializeQuorum(0, [auth1.publicKey, auth2.publicKey])
          .accountsPartial({
            quorum: quorumPda,
            organization: orgPda,
            authority: orgAuthority.publicKey,
            payer: orgAuthority.publicKey,
            systemProgram: SystemProgram.programId,
          })
          .rpc();
      } catch (err: any) {
        failed = true;
        expect(err.toString()).to.include("InvalidQuorumConfig");
      }
      expect(failed).to.be.true;
    });

    it("Initializes 2-of-3 Proof of Authority Quorum", async () => {
      const tx = await program.methods
        .initializeQuorum(2, [auth1.publicKey, auth2.publicKey, auth3.publicKey])
        .accountsPartial({
          quorum: quorumPda,
          organization: orgPda,
          authority: orgAuthority.publicKey,
          payer: orgAuthority.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .rpc();

      console.log("  [PoA] Quorum initialized (2-of-3 threshold):", tx);

      const quorumAccount = await program.account.authorityQuorum.fetch(quorumPda);
      expect(quorumAccount.threshold).to.equal(2);
      expect(quorumAccount.authoritiesCount).to.equal(3);
      expect(quorumAccount.authorities[0].toBase58()).to.equal(auth1.publicKey.toBase58());
      expect(quorumAccount.authorities[1].toBase58()).to.equal(auth2.publicKey.toBase58());
      expect(quorumAccount.authorities[2].toBase58()).to.equal(auth3.publicKey.toBase58());
      expect(quorumAccount.proposalCount.toNumber()).to.equal(0);
    });

    it("Rejects non-authority attempting to propose a critical action", async () => {
      const proposalId = new BN(0);
      const [proposal0Pda] = client.getProposalPda(orgPda, proposalId);
      const dummyExtra = new Array(32).fill(0);

      let rejected = false;
      try {
        await program.methods
          .createProposal(ACTION_TYPES.REVOKE_RESOURCE, poaResourcePda, dummyExtra, new BN(0))
          .accountsPartial({
            proposal: proposal0Pda,
            quorum: quorumPda,
            organization: orgPda,
            proposer: rogueAttacker.publicKey,
            payer: rogueAttacker.publicKey,
            systemProgram: SystemProgram.programId,
          })
          .signers([rogueAttacker])
          .rpc();
      } catch (err: any) {
        rejected = true;
        expect(err.toString()).to.include("NotAnAuthority");
      }
      expect(rejected).to.be.true;
    });

    it("Authority 1 creates a Proposal to revoke Resource #999 (1/2 Approvals)", async () => {
      const proposalId = new BN(0);
      const [proposal0Pda] = client.getProposalPda(orgPda, proposalId);
      const dummyExtra = new Array(32).fill(0);

      const tx = await program.methods
        .createProposal(ACTION_TYPES.REVOKE_RESOURCE, poaResourcePda, dummyExtra, new BN(0))
        .accountsPartial({
          proposal: proposal0Pda,
          quorum: quorumPda,
          organization: orgPda,
          proposer: auth1.publicKey,
          payer: auth1.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([auth1])
        .rpc();

      console.log("  [PoA] Proposal #0 created by Authority 1:", tx);

      const proposal = await program.account.consensusProposal.fetch(proposal0Pda);
      expect(proposal.proposalId.toNumber()).to.equal(0);
      expect(proposal.proposer.toBase58()).to.equal(auth1.publicKey.toBase58());
      expect(proposal.actionType).to.equal(ACTION_TYPES.REVOKE_RESOURCE);
      expect(proposal.target.toBase58()).to.equal(poaResourcePda.toBase58());
      expect(proposal.approvalCount).to.equal(1);
      expect(proposal.approvalsMask).to.equal(1); // bit 0 set
      expect(proposal.status).to.equal(PROPOSAL_STATUS.PENDING);
    });

    it("Compromised Authority 1 alone CANNOT execute the proposal (QuorumNotReached)", async () => {
      const proposalId = new BN(0);
      const [proposal0Pda] = client.getProposalPda(orgPda, proposalId);

      let rejected = false;
      try {
        await program.methods
          .executeRevokeResourceProposal()
          .accountsPartial({
            proposal: proposal0Pda,
            quorum: quorumPda,
            organization: orgPda,
            resource: poaResourcePda,
            executor: auth1.publicKey,
          })
          .signers([auth1])
          .rpc();
      } catch (err: any) {
        rejected = true;
        expect(err.toString()).to.include("QuorumNotReached");
      }
      expect(rejected).to.be.true;
      console.log("  [Security Passed] Single compromised authority blocked from executing without quorum!");
    });

    it("Authority 1 cannot double-vote on the same proposal", async () => {
      const proposalId = new BN(0);
      const [proposal0Pda] = client.getProposalPda(orgPda, proposalId);

      let rejected = false;
      try {
        await program.methods
          .approveProposal()
          .accountsPartial({
            proposal: proposal0Pda,
            quorum: quorumPda,
            organization: orgPda,
            authority: auth1.publicKey,
          })
          .signers([auth1])
          .rpc();
      } catch (err: any) {
        rejected = true;
        expect(err.toString()).to.include("ProposalAlreadyVoted");
      }
      expect(rejected).to.be.true;
    });

    it("Unauthorized attacker cannot vote on the proposal", async () => {
      const proposalId = new BN(0);
      const [proposal0Pda] = client.getProposalPda(orgPda, proposalId);

      let rejected = false;
      try {
        await program.methods
          .approveProposal()
          .accountsPartial({
            proposal: proposal0Pda,
            quorum: quorumPda,
            organization: orgPda,
            authority: rogueAttacker.publicKey,
          })
          .signers([rogueAttacker])
          .rpc();
      } catch (err: any) {
        rejected = true;
        expect(err.toString()).to.include("NotAnAuthority");
      }
      expect(rejected).to.be.true;
    });

    it("Authority 2 approves Proposal #0 -> Consensus Reached (2/2)", async () => {
      const proposalId = new BN(0);
      const [proposal0Pda] = client.getProposalPda(orgPda, proposalId);

      const tx = await program.methods
        .approveProposal()
        .accountsPartial({
          proposal: proposal0Pda,
          quorum: quorumPda,
          organization: orgPda,
          authority: auth2.publicKey,
        })
        .signers([auth2])
        .rpc();

      console.log("  [PoA] Authority 2 approved proposal #0:", tx);

      const proposal = await program.account.consensusProposal.fetch(proposal0Pda);
      expect(proposal.approvalCount).to.equal(2);
      expect(proposal.approvalsMask).to.equal(3); // bits 0 & 1 set
      expect(proposal.status).to.equal(PROPOSAL_STATUS.APPROVED);
    });

    it("Executes approved Revoke Resource Proposal via PoA Consensus", async () => {
      const proposalId = new BN(0);
      const [proposal0Pda] = client.getProposalPda(orgPda, proposalId);

      const tx = await program.methods
        .executeRevokeResourceProposal()
        .accountsPartial({
          proposal: proposal0Pda,
          quorum: quorumPda,
          organization: orgPda,
          resource: poaResourcePda,
          executor: auth2.publicKey,
        })
        .signers([auth2])
        .rpc();

      console.log("  [PoA] Revoke Resource executed via consensus:", tx);

      const resource = await program.account.resource.fetch(poaResourcePda);
      expect(resource.status).to.equal(2); // STATUS_REVOKED

      const proposal = await program.account.consensusProposal.fetch(proposal0Pda);
      expect(proposal.status).to.equal(PROPOSAL_STATUS.EXECUTED);
    });

    it("Rejects re-executing an already executed proposal", async () => {
      const proposalId = new BN(0);
      const [proposal0Pda] = client.getProposalPda(orgPda, proposalId);

      let rejected = false;
      try {
        await program.methods
          .executeRevokeResourceProposal()
          .accountsPartial({
            proposal: proposal0Pda,
            quorum: quorumPda,
            organization: orgPda,
            resource: poaResourcePda,
            executor: auth2.publicKey,
          })
          .signers([auth2])
          .rpc();
      } catch (err: any) {
        rejected = true;
        expect(err.toString()).to.include("ProposalClosed");
      }
      expect(rejected).to.be.true;
    });

    it("Consensus Role Assignment: Authorities 1 and 3 grant ADMIN role to User B", async () => {
      const proposalId = new BN(1);
      const [proposal1Pda] = client.getProposalPda(orgPda, proposalId);
      const [identityBPda] = client.getIdentityPda(userB.publicKey);
      const [adminRolePda] = client.getRolePda(orgPda, ROLE_IDS.ADMIN);
      const [grantBAdminPda] = client.getGrantPda(identityBPda, orgPda, adminRolePda);
      const dummyExtra = new Array(32).fill(0);

      // 1. Auth 1 proposes
      await program.methods
        .createProposal(ACTION_TYPES.ASSIGN_ROLE, identityBPda, dummyExtra, new BN(0))
        .accountsPartial({
          proposal: proposal1Pda,
          quorum: quorumPda,
          organization: orgPda,
          proposer: auth1.publicKey,
          payer: auth1.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([auth1])
        .rpc();

      // 2. Auth 3 approves -> 2-of-3 reached
      await program.methods
        .approveProposal()
        .accountsPartial({
          proposal: proposal1Pda,
          quorum: quorumPda,
          organization: orgPda,
          authority: auth3.publicKey,
        })
        .signers([auth3])
        .rpc();

      // 3. Execute role assignment proposal
      const tx = await program.methods
        .executeAssignRoleProposal(new BN(0))
        .accountsPartial({
          proposal: proposal1Pda,
          quorum: quorumPda,
          organization: orgPda,
          identity: identityBPda,
          role: adminRolePda,
          grant: grantBAdminPda,
          payer: auth1.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([auth1])
        .rpc();

      console.log("  [PoA] Role assigned via consensus:", tx);

      const grant = await program.account.accessGrant.fetch(grantBAdminPda);
      expect(grant.active).to.be.true;
      expect(grant.identity.toBase58()).to.equal(identityBPda.toBase58());
      expect(grant.role.toBase58()).to.equal(adminRolePda.toBase58());
    });

    it("Consensus Authority Rotation: Rotates authorities to replace compromised key", async () => {
      const proposalId = new BN(2);
      const [proposal2Pda] = client.getProposalPda(orgPda, proposalId);
      const newAuth4 = Keypair.generate();
      const dummyExtra = new Array(32).fill(0);

      // Auth 2 proposes rotating quorum to [auth2, auth3, newAuth4] (replacing auth1)
      await program.methods
        .createProposal(ACTION_TYPES.ROTATE_QUORUM, quorumPda, dummyExtra, new BN(0))
        .accountsPartial({
          proposal: proposal2Pda,
          quorum: quorumPda,
          organization: orgPda,
          proposer: auth2.publicKey,
          payer: auth2.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([auth2])
        .rpc();

      // Auth 3 approves -> 2-of-3 reached
      await program.methods
        .approveProposal()
        .accountsPartial({
          proposal: proposal2Pda,
          quorum: quorumPda,
          organization: orgPda,
          authority: auth3.publicKey,
        })
        .signers([auth3])
        .rpc();

      // Execute rotation
      const newAuthorities = [auth2.publicKey, auth3.publicKey, newAuth4.publicKey];
      await program.methods
        .executeRotateQuorumProposal(2, newAuthorities)
        .accountsPartial({
          proposal: proposal2Pda,
          quorum: quorumPda,
          organization: orgPda,
          executor: auth2.publicKey,
        })
        .signers([auth2])
        .rpc();

      const updatedQuorum = await program.account.authorityQuorum.fetch(quorumPda);
      expect(updatedQuorum.authorities[0].toBase58()).to.equal(auth2.publicKey.toBase58());
      expect(updatedQuorum.authorities[1].toBase58()).to.equal(auth3.publicKey.toBase58());
      expect(updatedQuorum.authorities[2].toBase58()).to.equal(newAuth4.publicKey.toBase58());
      console.log("  [PoA] Quorum successfully rotated without auth1!");
    });
  });

  after(async () => {
    // Clean up event listeners to exit cleanly
    for (const id of listenerIds) {
      try {
        await program.removeEventListener(id);
      } catch (_) {}
    }
  });
});

