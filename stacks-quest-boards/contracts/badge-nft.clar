;; title: badge-nft
;; summary: SIP-009 compliant NFT used as quest badges
;; note: built with explicit admin/minter roles and token-level URIs

;; token definition
(define-non-fungible-token badge uint)

;; constants
(define-constant err-not-owner (err u100))
(define-constant err-not-minter (err u101))
