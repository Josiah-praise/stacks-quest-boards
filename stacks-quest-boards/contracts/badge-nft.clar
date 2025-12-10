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
(define-constant err-mint-paused (err u108))
(define-constant contract-owner tx-sender)
(define-data-var authorized-minter principal contract-owner)
(define-data-var base-uri (optional (string-utf8 256)) none)
(define-data-var max-supply (optional uint) none)
(define-data-var last-token-id uint u0)
(define-data-var total-supply uint u0)
(define-data-var mint-paused bool false)
(define-map token-uri { id: uint } { uri: (string-utf8 256) })
(define-private (is-owner (who principal))
  (is-eq who contract-owner))
(define-private (is-minter (who principal))
  (is-eq who (var-get authorized-minter)))
(define-private (assert-owner (who principal))
  (if (is-owner who) true err-not-owner))
(define-private (assert-minter (who principal))
  (if (is-minter who) true err-not-minter))
(define-private (ensure-uri (uri (string-utf8 256)))
  (if (> (len uri) u0) true err-uri-required))
(define-private (next-token-id)
  (let ((new-id (+ (var-get last-token-id) u1)))
    (begin
      (var-set last-token-id new-id)
      new-id)))
(define-private (increment-supply)
  (var-set total-supply (+ (var-get total-supply) u1)))
(define-private (enforce-supply-limit)
  (match (var-get max-supply)
    max (if (<= (+ (var-get total-supply) u1) max) true err-supply-exceeded)
    none true))
(define-private (set-uri! (id uint) (uri (string-utf8 256)))
  (map-set token-uri { id: id } { uri: uri }))
(define-private (record-mint (recipient principal) (token-id uint) (uri (string-utf8 256)))
  (begin
    (enforce-supply-limit)
    (asserts! (not (is-some (nft-get-owner? badge token-id))) err-token-exists)
    (let ((mint-result (nft-mint? badge token-id recipient)))
      (if (is-ok mint-result)
        (begin
          (set-uri! token-id uri)
          (increment-supply)
          (ok token-id))
        mint-result))))
(define-private (apply-base-uri (uri (string-utf8 256)))
  (match (var-get base-uri)
    base (concat base uri)
    none uri))

;; admin: update authorized minter
(define-public (set-minter (minter principal))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (ok (var-set authorized-minter minter))))

;; admin: update base URI
(define-public (set-base-uri (uri (string-utf8 256)))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (ok (var-set base-uri (some uri)))))

;; admin: set max supply (cannot be below current supply)
(define-public (set-max-supply (limit uint))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (asserts! (>= limit (var-get total-supply)) err-max-supply-too-low)
    (ok (var-set max-supply (some limit)))))

;; admin: remove max supply limit
(define-public (clear-max-supply)
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (ok (var-set max-supply none))))

;; admin: pause/unpause minting
(define-public (set-mint-paused (flag bool))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (ok (var-set mint-paused flag))))

;; admin: clear base uri
(define-public (clear-base-uri)
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (ok (var-set base-uri none))))

;; read: current minter
(define-read-only (get-minter)
  (ok (var-get authorized-minter)))

;; read: base uri
(define-read-only (get-base-uri)
  (ok (var-get base-uri)))

;; read: max supply
(define-read-only (get-max-supply)
  (ok (var-get max-supply)))

;; read: total supply
(define-read-only (get-total-supply)
  (ok (var-get total-supply)))

;; read: last token id
(define-read-only (get-last-token-id)
  (ok (var-get last-token-id)))

;; read: token uri
(define-read-only (get-token-uri (id uint))
  (match (map-get? token-uri { id: id })
    entry (ok (apply-base-uri (get uri entry)))
    none err-token-not-found))

;; read: raw token uri (without base)
(define-read-only (get-token-uri-raw (id uint))
  (match (map-get? token-uri { id: id })
    entry (ok (get uri entry))
    none err-token-not-found))

;; read: token owner
(define-read-only (get-owner (id uint))
  (match (nft-get-owner? badge id)
    owner (ok owner)
    none err-token-not-found))
(define-private (get-owner-or-err (id uint))
  (match (nft-get-owner? badge id)
    owner (ok owner)
    none err-token-not-found))

;; public: transfer token
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (match (get-owner-or-err token-id)
    owner
      (if (is-eq owner sender)
          (let ((res (nft-transfer? badge token-id sender recipient)))
            (match res
              ok (begin (print { event: "transfer", id: token-id, from: sender, to: recipient }) res)
              err res))
          err-not-token-owner)
    err err))

;; public: mint new badge (minter only)
(define-public (mint (recipient principal) (uri (string-utf8 256)))
  (begin
    (asserts! (assert-minter tx-sender) err-not-minter)
    (asserts! (not (var-get mint-paused)) err-mint-paused)
    (asserts! (ensure-uri uri) err-uri-required)
    (let ((new-id (next-token-id)))
      (let ((result (record-mint recipient new-id uri)))
        (match result
          id (begin (print { event: "mint", id: id, to: recipient, uri: uri }) result)
          err result)))))

;; read: token exists?
(define-read-only (token-exists (id uint))
  (ok (is-some (nft-get-owner? badge id))))

;; read: contract owner
(define-read-only (get-owner-principal)
  (ok contract-owner))
