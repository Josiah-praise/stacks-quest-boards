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
it("mints a badge and records uri, minter, owner, and minted-at", () => {const mintResult = mintBadge(alice, "ipfs://badge-1");
expect(mintResult.result).toBeOk(Cl.uint(1));
const mintedAtResult = simnet.callReadOnlyFn(
"badge-nft",
"get-token-minted-at",
[Cl.uint(1)],
alice,
);
expect(mintedAtResult.result).toBeOk(expect.anything());
const mintedAtCv = (mintedAtResult.result as ResponseOkCV<UIntCV>).value;
expect(mintedAtCv).toBeUint(mintedAtCv.value);
expect(mintedAtCv.value).toBeGreaterThan(0n);
const tokenInfo = simnet.callReadOnlyFn(
"badge-nft",
"get-token-info",
[Cl.uint(1)],
alice,
);
expect(tokenInfo.result).toBeOk(
Cl.tuple({
owner: principalCV(alice),uri: Cl.stringUtf8("ipfs://badge-1"),
minter: principalCV(deployer),
"minted-at": mintedAtCv,
}),
);
const supply = simnet.callReadOnlyFn("badge-nft", "get-total-supply", [],
alice);
expect(supply.result).toBeOk(Cl.uint(1));
});
it("rejects minting from a non-minter", () => {
const mintResult = mintBadge(alice, "ipfs://badge-unauthorized", alice);
expect(mintResult.result).toBeErr(Cl.uint(101)); // err-not-minter
});
it("respects the mint pause flag", () => {
const pause = simnet.callPublicFn(
"badge-nft",
"set-mint-paused",
[Cl.bool(true)],
deployer,
);expect(pause.result).toBeOk(Cl.bool(true));
const mintResult = mintBadge(alice, "ipfs://badge-paused");
expect(mintResult.result).toBeErr(Cl.uint(108)); // err-mint-paused
});
it("requires burn toggle and ownership, and clears metadata on burn", ()
=> {
const mintResult = mintBadge(alice, "ipfs://badge-burn");
expect(mintResult.result).toBeOk(Cl.uint(1));
const burnWhileDisabled = simnet.callPublicFn("badge-nft", "burn",
[Cl.uint(1)], alice);
expect(burnWhileDisabled.result).toBeErr(Cl.uint(111)); // err-burn-
disabled
const enableBurn = simnet.callPublicFn(
"badge-nft",
"set-burn-enabled",
[Cl.bool(true)],
deployer,
);
expect(enableBurn.result).toBeOk(Cl.bool(true));
const burnByNonOwner = simnet.callPublicFn("badge-nft", "burn",[Cl.uint(1)], bob);
expect(burnByNonOwner.result).toBeErr(Cl.uint(105)); // err-not-token-
owner
const burnResult = simnet.callPublicFn("badge-nft", "burn", [Cl.uint(1)],
alice);
expect(burnResult.result).toBeOk(Cl.bool(true));
const tokenInfo = simnet.callReadOnlyFn(
"badge-nft",
"get-token-info",
[Cl.uint(1)],
alice,
);
expect(tokenInfo.result).toBeErr(Cl.uint(106)); // err-token-not-found
const mintedAt = simnet.callReadOnlyFn(
"badge-nft",
"get-token-minted-at",
[Cl.uint(1)],
alice,
);
expect(mintedAt.result).toBeErr(Cl.uint(106)); // err-token-not-foundconst supply = simnet.callReadOnlyFn("badge-nft", "get-total-supply", [],
alice);
expect(supply.result).toBeOk(Cl.uint(0));
});
});