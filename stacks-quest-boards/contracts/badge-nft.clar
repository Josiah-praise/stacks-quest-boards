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
(define-constant err-invalid-recipient (err u109))
(define-constant err-metadata-locked (err u110))
(define-constant err-burn-disabled (err u111))
(define-constant contract-version u1)
(define-constant contract-owner tx-sender)
(define-data-var contract-admin principal contract-owner)
(define-data-var authorized-minter principal contract-owner)
(define-data-var base-uri (optional (string-utf8 256)) none)
(define-data-var max-supply (optional uint) none)
(define-data-var last-token-id uint u0)
(define-data-var total-supply uint u0)
(define-data-var mint-paused bool false)
(define-data-var metadata-locked bool false)
(define-data-var burn-enabled bool false)
(define-data-var collection-name (string-utf8 64) "Quest Badge")
(define-data-var collection-symbol (string-utf8 32) "QBADGE")
(define-map token-uri { id: uint } { uri: (string-utf8 256) })
(define-map token-minter { id: uint } { minter: principal })
(define-private (is-owner (who principal))
  (is-eq who (var-get contract-admin)))
(define-private (is-minter (who principal))
  (is-eq who (var-get authorized-minter)))
(define-private (assert-owner (who principal))
  (if (is-owner who) true err-not-owner))
(define-private (assert-minter (who principal))
  (if (is-minter who) true err-not-minter))
(define-private (assert-valid-recipient (who principal))
  (if (is-eq who 'SP000000000000000000002Q6VF78) err-invalid-recipient true))
(define-private (ensure-uri (uri (string-utf8 256)))
  (if (> (len uri) u0) true err-uri-required))
(define-private (next-token-id)
  (let ((new-id (+ (var-get last-token-id) u1)))
    (begin
      (var-set last-token-id new-id)
      new-id)))
(define-private (increment-supply)
  (var-set total-supply (+ (var-get total-supply) u1)))
(define-private (decrement-supply)
  (var-set total-supply (- (var-get total-supply) u1)))
(define-private (enforce-supply-limit)
  (match (var-get max-supply)
    max (if (<= (+ (var-get total-supply) u1) max) true err-supply-exceeded)
    none true))
(define-private (set-uri! (id uint) (uri (string-utf8 256)))
  (map-set token-uri { id: id } { uri: uri }))
(define-private (clear-uri! (id uint))
  (map-delete token-uri { id: id }))
(define-private (record-mint (recipient principal) (token-id uint) (uri (string-utf8 256)))
  (begin
    (enforce-supply-limit)
    (asserts! (not (is-some (nft-get-owner? badge token-id))) err-token-exists)
    (let ((mint-result (nft-mint? badge token-id recipient)))
      (if (is-ok mint-result)
        (begin
          (set-uri! token-id uri)
          (map-set token-minter { id: token-id } { minter: tx-sender })
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
    (var-set authorized-minter minter)
    (print { event: "set-minter", minter: minter })
    (ok true)))

;; admin: transfer admin role
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (var-set contract-admin new-admin)
    (print { event: "set-admin", admin: new-admin })
    (ok true)))

;; admin: update base URI
(define-public (set-base-uri (uri (string-utf8 256)))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (var-set base-uri (some uri))
    (print { event: "set-base-uri", uri: uri })
    (ok true)))

;; admin: set max supply (cannot be below current supply)
(define-public (set-max-supply (limit uint))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (asserts! (>= limit (var-get total-supply)) err-max-supply-too-low)
    (var-set max-supply (some limit))
    (print { event: "set-max-supply", limit: limit })
    (ok true)))

;; admin: remove max supply limit
(define-public (clear-max-supply)
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (var-set max-supply none)
    (print { event: "clear-max-supply" })
    (ok true)))

;; admin: pause/unpause minting
(define-public (set-mint-paused (flag bool))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (var-set mint-paused flag)
    (print { event: "set-mint-paused", paused: flag })
    (ok true)))

;; admin: toggle burn ability
(define-public (set-burn-enabled (flag bool))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (var-set burn-enabled flag)
    (print { event: "set-burn-enabled", enabled: flag })
    (ok true)))

;; admin: clear base uri
(define-public (clear-base-uri)
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (var-set base-uri none)
    (print { event: "clear-base-uri" })
    (ok true)))

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

;; read: remaining supply (if capped)
(define-read-only (get-remaining-supply)
  (match (var-get max-supply)
    max (ok (some (- max (var-get total-supply))))
    none (ok none)))

;; read: mint pause state
(define-read-only (is-mint-paused)
  (ok (var-get mint-paused)))

;; read: last token id
(define-read-only (get-last-token-id)
  (ok (var-get last-token-id)))

;; read: next token id
(define-read-only (get-next-token-id)
  (ok (+ (var-get last-token-id) u1)))

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

;; read: token minter
(define-read-only (get-token-minter (id uint))
  (match (map-get? token-minter { id: id })
    entry (ok (get minter entry))
    none err-token-not-found))

;; read: collection name
(define-read-only (get-name)
  (ok (var-get collection-name)))

;; read: collection symbol
(define-read-only (get-symbol)
  (ok (var-get collection-symbol)))

;; read: token owner
(define-read-only (get-owner (id uint))
  (match (nft-get-owner? badge id)
    owner (ok owner)
    none err-token-not-found))
(define-private (get-owner-or-err (id uint))
  (match (nft-get-owner? badge id)
    owner (ok owner)
    none err-token-not-found))

;; admin: update token uri
(define-public (set-token-uri (id uint) (uri (string-utf8 256)))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (asserts! (not (var-get metadata-locked)) err-metadata-locked)
    (asserts! (ensure-uri uri) err-uri-required)
    (asserts! (token-exists id) err-token-not-found)
    (set-uri! id uri)
    (print { event: "set-token-uri", id: id, uri: uri })
    (ok true)))

;; admin: update collection name
(define-public (set-name (name (string-utf8 64)))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (asserts! (not (var-get metadata-locked)) err-metadata-locked)
    (var-set collection-name name)
    (print { event: "set-name", name: name })
    (ok true)))

;; admin: update collection symbol
(define-public (set-symbol (symbol (string-utf8 32)))
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (asserts! (not (var-get metadata-locked)) err-metadata-locked)
    (var-set collection-symbol symbol)
    (print { event: "set-symbol", symbol: symbol })
    (ok true)))

;; admin: lock metadata updates permanently
(define-public (lock-metadata)
  (begin
    (asserts! (assert-owner tx-sender) err-not-owner)
    (var-set metadata-locked true)
    (print { event: "lock-metadata" })
    (ok true)))

;; public: transfer token
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (match (get-owner-or-err token-id)
    owner
      (if (and (is-eq owner sender) (is-eq true (assert-valid-recipient recipient)))
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
    (asserts! (assert-valid-recipient recipient) err-invalid-recipient)
    (asserts! (ensure-uri uri) err-uri-required)
    (let ((new-id (next-token-id)))
      (let ((result (record-mint recipient new-id uri)))
        (match result
          id (begin (print { event: "mint", id: id, to: recipient, uri: uri }) result)
          err result)))))

;; public: burn token (owner only, if enabled)
(define-public (burn (token-id uint))
  (match (get-owner-or-err token-id)
    owner
      (if (is-eq true (var-get burn-enabled))
          (if (is-eq owner tx-sender)
              (let ((res (nft-burn? badge token-id owner)))
                (match res
                  ok (begin
                        (clear-uri! token-id)
                        (map-delete token-minter { id: token-id })
                        (decrement-supply)
                        (print { event: "burn", id: token-id, by: tx-sender })
                        res)
                  err res))
              err-not-token-owner)
          err-burn-disabled)
    err err))

;; read: can mint now?
(define-read-only (can-mint)
  (ok (and (not (var-get mint-paused))
           (match (var-get max-supply)
             max (< (var-get total-supply) max)
             none true))))

;; read: token exists?
(define-read-only (token-exists (id uint))
  (ok (is-some (nft-get-owner? badge id))))

;; read: metadata lock status
(define-read-only (is-metadata-locked)
  (ok (var-get metadata-locked)))

;; read: burn enabled?
(define-read-only (is-burn-enabled)
  (ok (var-get burn-enabled)))

;; read: contract owner
(define-read-only (get-owner-principal)
  (ok (var-get contract-admin)))

;; read: contract version
(define-read-only (get-version)
  (ok contract-version))
