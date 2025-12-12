# Badge NFT Contract Documentation

## Overview

The `badge-nft` contract is a SIP-009 compliant non-fungible token (NFT) implementation designed for use as quest badges in the Stacks Quest Boards system. The contract features an explicit admin/minter role model, token-level URIs, and comprehensive metadata management capabilities.

**Key Features:**
- SIP-009 compliant NFT standard
- Admin and minter role separation
- Token-level URI management with optional base URI
- Supply limit enforcement
- Mint pause/unpause functionality
- Burn toggle (enabled/disabled)
- Metadata locking mechanism
- Clarity 4 features including `minted-at` tracking via `stacks-block-time`

**Contract Version:** 1

---

## Constants and Errors

### Constants
- `contract-version`: `u1` - Current version of the contract
- `contract-owner`: Initial deployer address (set at deployment)

### Error Codes
| Error Code | Constant | Description |
|------------|----------|-------------|
| `u100` | `err-not-owner` | Caller is not the contract admin |
| `u101` | `err-not-minter` | Caller is not the authorized minter |
| `u102` | `err-uri-required` | URI is required but was empty or missing |
| `u103` | `err-supply-exceeded` | Minting would exceed the maximum supply limit |
| `u104` | `err-token-exists` | Token with the given ID already exists |
| `u105` | `err-not-token-owner` | Caller is not the owner of the specified token |
| `u106` | `err-token-not-found` | Token with the given ID does not exist |
| `u107` | `err-max-supply-too-low` | Attempted to set max supply below current total supply |
| `u108` | `err-mint-paused` | Minting is currently paused |
| `u109` | `err-invalid-recipient` | Recipient address is invalid (cannot be `SP000000000000000000002Q6VF78`) |
| `u110` | `err-metadata-locked` | Metadata has been permanently locked and cannot be modified |
| `u111` | `err-burn-disabled` | Burning is currently disabled |

