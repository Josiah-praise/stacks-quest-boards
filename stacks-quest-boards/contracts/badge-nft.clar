;; title: badge-nft
;; summary: SIP-009 compliant NFT used as quest badges
;; note: built with explicit admin/minter roles and token-level URIs

;; token definition
(define-non-fungible-token badge uint)

;; constants
(define-constant err-not-owner (err u100))
(define-constant err-not-minter (err u101))
(define-constant err-uri-required (err u102))
(define-constant err-supply-exceeded (err u103))
(define-constant err-token-exists (err u104))
(define-constant err-not-token-owner (err u105))
(define-constant err-token-not-found (err u106))
(define-constant err-max-supply-too-low (err u107))
(define-constant contract-owner tx-sender)
(define-data-var authorized-minter principal contract-owner)
(define-data-var base-uri (optional (string-utf8 256)) none)
(define-data-var max-supply (optional uint) none)
(define-data-var last-token-id uint u0)
(define-data-var total-supply uint u0)
(define-map token-uri { id: uint } { uri: (string-utf8 256) })
(define-private (is-owner (who principal))
  (is-eq who contract-owner))
(define-private (is-minter (who principal))
  (is-eq who (var-get authorized-minter)))
