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

---

## Admin Functions

All admin functions require the caller to be the contract admin (`contract-admin`). All functions emit events via `print` statements.

### `set-minter`
**Signature:** `(define-public (set-minter (minter principal)))`

Updates the authorized minter address. The new minter cannot be the invalid recipient address.

**Preconditions:**
- Caller must be admin
- `minter` must be a valid recipient (not `SP000000000000000000002Q6VF78`)

**Returns:** `(ok true)` on success

**Event:** `{ event: "set-minter", minter: minter }`

### `set-admin`
**Signature:** `(define-public (set-admin (new-admin principal)))`

Transfers the admin role to a new principal. This is a critical function that permanently changes contract control.

**Preconditions:**
- Caller must be admin
- `new-admin` must be a valid recipient (not `SP000000000000000000002Q6VF78`)

**Returns:** `(ok true)` on success

**Event:** `{ event: "set-admin", admin: new-admin }`

### `set-base-uri`
**Signature:** `(define-public (set-base-uri (uri (string-utf8 256))))`

Sets a base URI prefix that will be prepended to all token URIs. If set, `get-token-uri` will return `base-uri + token-uri`.

**Preconditions:**
- Caller must be admin
- `uri` must be non-empty

**Returns:** `(ok true)` on success

**Event:** `{ event: "set-base-uri", uri: uri }`

### `clear-base-uri`
**Signature:** `(define-public (clear-base-uri))`

Removes the base URI, causing tokens to use only their individual URIs.

**Preconditions:**
- Caller must be admin

**Returns:** `(ok true)` on success

**Event:** `{ event: "clear-base-uri" }`

### `set-max-supply`
**Signature:** `(define-public (set-max-supply (limit uint)))`

Sets a maximum supply limit for tokens. Cannot be set below the current total supply.

**Preconditions:**
- Caller must be admin
- `limit` must be >= current `total-supply`

**Returns:** `(ok true)` on success

**Event:** `{ event: "set-max-supply", limit: limit }`

### `clear-max-supply`
**Signature:** `(define-public (clear-max-supply))`

Removes the maximum supply limit, allowing unlimited minting.

**Preconditions:**
- Caller must be admin

**Returns:** `(ok true)` on success

**Event:** `{ event: "clear-max-supply" }`

### `set-mint-paused`
**Signature:** `(define-public (set-mint-paused (flag bool)))`

Pauses or unpauses minting. When paused, `mint` function will fail with `err-mint-paused`.

**Preconditions:**
- Caller must be admin

**Returns:** `(ok true)` on success

**Event:** `{ event: "set-mint-paused", paused: flag }`

### `set-burn-enabled`
**Signature:** `(define-public (set-burn-enabled (flag bool)))`

Enables or disables token burning. When disabled, `burn` function will fail with `err-burn-disabled`.

**Preconditions:**
- Caller must be admin

**Returns:** `(ok true)` on success

**Event:** `{ event: "set-burn-enabled", enabled: flag }`

### `set-name`
**Signature:** `(define-public (set-name (name (string-utf8 64))))`

Updates the collection name. Requires metadata to be unlocked.

**Preconditions:**
- Caller must be admin
- Metadata must not be locked
- `name` must be non-empty

**Returns:** `(ok true)` on success

**Event:** `{ event: "set-name", name: name }`

### `set-symbol`
**Signature:** `(define-public (set-symbol (symbol (string-utf8 32))))`

Updates the collection symbol. Requires metadata to be unlocked.

**Preconditions:**
- Caller must be admin
- Metadata must not be locked
- `symbol` must be non-empty

**Returns:** `(ok true)` on success

**Event:** `{ event: "set-symbol", symbol: symbol }`

### `set-token-uri`
**Signature:** `(define-public (set-token-uri (id uint) (uri (string-utf8 256))))`

Updates the URI for a specific token. Requires metadata to be unlocked and token to exist.

**Preconditions:**
- Caller must be admin
- Metadata must not be locked
- Token with `id` must exist
- `uri` must be non-empty

**Returns:** `(ok true)` on success

**Event:** `{ event: "set-token-uri", id: id, uri: uri }`

### `lock-metadata`
**Signature:** `(define-public (lock-metadata))`

Permanently locks all metadata updates. Once locked, `set-name`, `set-symbol`, and `set-token-uri` will fail. This action is irreversible.

**Preconditions:**
- Caller must be admin

**Returns:** `(ok true)` on success

**Event:** `{ event: "lock-metadata" }`

