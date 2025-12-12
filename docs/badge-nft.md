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

