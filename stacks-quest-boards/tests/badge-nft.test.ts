import { describe, expect, it } from "vitest";
import { Cl, type ResponseOkCV, type UIntCV } from "@stacks/transactions";

// Get test accounts from simnet
const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!; // Contract deployer (default admin and minter)
const alice = accounts.get("wallet_1")!; // Test user account
const bob = accounts.get("wallet_2")!; // Test user account

// Helper function to convert address string to principal Clarity value
const principalCV = (address: string) => Cl.standardPrincipal(address);

// Helper function to mint a badge NFT
// Defaults: recipient=alice, uri="ipfs://badge-1", caller=deployer
const mintBadge = (recipient = alice, uri = "ipfs://badge-1", caller =
deployer) =>
simnet.callPublicFn(
"badge-nft",
"mint",
[principalCV(recipient), Cl.stringUtf8(uri)],
caller,
);
describe("badge-nft", () => {
  // Test: Verify minting functionality and data recording
  // This test ensures that minting records all required information including minted-at timestamp
  it("mints a badge and records uri, minter, owner, and minted-at", () => {
    // Mint a badge to alice with a specific URI
    const mintResult = mintBadge(alice, "ipfs://badge-1");
    // Verify minting succeeded and returned token ID 1
    expect(mintResult.result).toBeOk(Cl.uint(1));
    
    // Retrieve the minted-at timestamp (Clarity 4 feature using stacks-block-time)
    const mintedAtResult = simnet.callReadOnlyFn(
      "badge-nft",
      "get-token-minted-at",
      [Cl.uint(1)],
      alice,
    );
    // Verify minted-at was recorded successfully
    expect(mintedAtResult.result).toBeOk(expect.anything());
    const mintedAtCv = (mintedAtResult.result as ResponseOkCV<UIntCV>).value;
    // Verify minted-at is a valid uint and greater than 0
    expect(mintedAtCv).toBeUint(mintedAtCv.value);
    expect(mintedAtCv.value).toBeGreaterThan(0n);
    
    // Get comprehensive token information
    const tokenInfo = simnet.callReadOnlyFn(
      "badge-nft",
      "get-token-info",
      [Cl.uint(1)],
      alice,
    );
    // Verify all token data is correctly recorded: owner, URI, minter, and minted-at
    expect(tokenInfo.result).toBeOk(
      Cl.tuple({
        owner: principalCV(alice),
        uri: Cl.stringUtf8("ipfs://badge-1"),
        minter: principalCV(deployer),
        "minted-at": mintedAtCv,
      }),
    );
    
    // Verify total supply was incremented
    const supply = simnet.callReadOnlyFn("badge-nft", "get-total-supply", [], alice);
    expect(supply.result).toBeOk(Cl.uint(1));
  });
  // Test: Verify access control - only authorized minter can mint
  // This test ensures that non-minter addresses cannot mint tokens
  it("rejects minting from a non-minter", () => {
    // Attempt to mint as alice (who is not the minter)
    const mintResult = mintBadge(alice, "ipfs://badge-unauthorized", alice);
    // Verify minting was rejected with err-not-minter error code
    expect(mintResult.result).toBeErr(Cl.uint(101)); // err-not-minter
  });
  // Test: Verify mint pause functionality
  // This test ensures that admin can pause minting and paused state prevents new mints
  it("respects the mint pause flag", () => {
    // Admin pauses minting
    const pause = simnet.callPublicFn(
      "badge-nft",
      "set-mint-paused",
      [Cl.bool(true)],
      deployer,
    );
    // Verify pause was successful
    expect(pause.result).toBeOk(Cl.bool(true));
    
    // Attempt to mint while paused (should fail)
    const mintResult = mintBadge(alice, "ipfs://badge-paused");
    // Verify minting was rejected with err-mint-paused error code
    expect(mintResult.result).toBeErr(Cl.uint(108)); // err-mint-paused
  });
  // Test: Verify burn functionality with access control and metadata cleanup
  // This test ensures burn requires ownership, burn must be enabled, and all metadata is cleaned up
  it("requires burn toggle and ownership, and clears metadata on burn", () => {
    // First, mint a badge to alice for testing burn functionality
    const mintResult = mintBadge(alice, "ipfs://badge-burn");
    expect(mintResult.result).toBeOk(Cl.uint(1));
    
    // Attempt to burn while burn is disabled (should fail)
    const burnWhileDisabled = simnet.callPublicFn("badge-nft", "burn", [Cl.uint(1)], alice);
    // Verify burn was rejected with err-burn-disabled error code
    expect(burnWhileDisabled.result).toBeErr(Cl.uint(111)); // err-burn-disabled
    
    // Admin enables burning
    const enableBurn = simnet.callPublicFn(
      "badge-nft",
      "set-burn-enabled",
      [Cl.bool(true)],
      deployer,
    );
    // Verify burn was enabled successfully
    expect(enableBurn.result).toBeOk(Cl.bool(true));
    
    // Attempt to burn by non-owner (bob trying to burn alice's token)
    const burnByNonOwner = simnet.callPublicFn("badge-nft", "burn", [Cl.uint(1)], bob);
    // Verify burn was rejected with err-not-token-owner error code
    expect(burnByNonOwner.result).toBeErr(Cl.uint(105)); // err-not-token-owner
    
    // Owner (alice) burns the token
    const burnResult = simnet.callPublicFn("badge-nft", "burn", [Cl.uint(1)], alice);
    // Verify burn was successful
    expect(burnResult.result).toBeOk(Cl.bool(true));
    
    // Verify token info is no longer available (token was deleted)
    const tokenInfo = simnet.callReadOnlyFn(
      "badge-nft",
      "get-token-info",
      [Cl.uint(1)],
      alice,
    );
    // Verify token not found error (token was burned and cleaned up)
    expect(tokenInfo.result).toBeErr(Cl.uint(106)); // err-token-not-found
    
    // Verify minted-at record was also deleted
    const mintedAt = simnet.callReadOnlyFn(
      "badge-nft",
      "get-token-minted-at",
      [Cl.uint(1)],
      alice,
    );
    // Verify minted-at record not found (cleaned up during burn)
    expect(mintedAt.result).toBeErr(Cl.uint(106)); // err-token-not-found
    
    // Verify total supply was decremented back to 0
    const supply = simnet.callReadOnlyFn("badge-nft", "get-total-supply", [], alice);
    expect(supply.result).toBeOk(Cl.uint(0));
  });
});