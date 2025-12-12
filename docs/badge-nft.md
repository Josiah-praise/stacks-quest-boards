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

---

## State Variables and Roles

### Roles
- **Admin** (`contract-admin`): Has full control over contract configuration, metadata, and settings. Can transfer admin role to another principal.
- **Minter** (`authorized-minter`): Authorized to mint new badge tokens. Set by admin.

### State Variables
- `contract-admin`: Current admin principal (initialized to deployer)
- `authorized-minter`: Principal authorized to mint tokens (initialized to deployer)
- `base-uri`: Optional base URI prefix for all token URIs
- `max-supply`: Optional maximum supply limit for tokens
- `last-token-id`: ID of the most recently minted token
- `total-supply`: Current total number of minted tokens
- `mint-paused`: Boolean flag to pause/unpause minting
- `metadata-locked`: Boolean flag indicating if metadata is permanently locked
- `burn-enabled`: Boolean flag to enable/disable token burning
- `collection-name`: Collection name (default: "Quest Badge")
- `collection-symbol`: Collection symbol (default: "QBADGE")

### Token-Level Data Maps
- `token-uri`: Maps token ID to its URI string
- `token-minter`: Maps token ID to the principal that minted it
- `token-minted-at`: Maps token ID to the block time when it was minted (Clarity 4 feature)

