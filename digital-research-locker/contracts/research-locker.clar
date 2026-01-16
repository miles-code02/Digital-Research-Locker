;; Digital Research Locker Contract
;; Blockchain-based storage system for academic records and research

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))

;; Data Variables
(define-data-var document-nonce uint u0)

;; Data Maps
(define-map documents
  uint
  {
    owner: principal,
    title: (string-ascii 100),
    document-hash: (string-ascii 64),
    document-type: (string-ascii 50),
    timestamp: uint,
    public: bool
  }
)

(define-map user-document-count principal uint)

;; Read-only functions
(define-read-only (get-document (document-id uint))
  (map-get? documents document-id)
)

(define-read-only (get-user-document-count (user principal))
  (default-to u0 (map-get? user-document-count user))
)

(define-read-only (get-document-nonce)
  (var-get document-nonce)
)

;; Public functions
;; #[allow(unchecked_data)]
(define-public (store-document 
  (title (string-ascii 100))
  (document-hash (string-ascii 64))
  (document-type (string-ascii 50))
  (public bool))
  (let
    (
      (document-id (var-get document-nonce))
      (owner tx-sender)
    )
    (map-set documents document-id
      {
        owner: owner,
        title: title,
        document-hash: document-hash,
        document-type: document-type,
        timestamp: stacks-block-height,
        public: public
      }
    )
    (map-set user-document-count owner (+ (get-user-document-count owner) u1))
    (var-set document-nonce (+ document-id u1))
    (ok document-id)
  )
)

;; Data Maps
(define-map document-access
  { document-id: uint, accessor: principal }
  bool
)

;; Read-only functions
(define-read-only (has-access (document-id uint) (accessor principal))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) false))
    )
    (or 
      (is-eq accessor (get owner doc))
      (get public doc)
      (default-to false (map-get? document-access { document-id: document-id, accessor: accessor }))
    )
  )
)

;; Public functions
;; #[allow(unchecked_data)]
(define-public (grant-access (document-id uint) (accessor principal))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (map-set document-access 
      { document-id: document-id, accessor: accessor }
      true
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (revoke-access (document-id uint) (accessor principal))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (map-delete document-access { document-id: document-id, accessor: accessor })
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (update-visibility (document-id uint) (public bool))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (map-set documents document-id (merge doc { public: public }))
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (batch-grant-access (document-id uint) (accessors (list 10 principal)))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (ok (map grant-access-helper (list { id: document-id, accessor: (element-at? accessors u0) }
                                       { id: document-id, accessor: (element-at? accessors u1) }
                                       { id: document-id, accessor: (element-at? accessors u2) }
                                       { id: document-id, accessor: (element-at? accessors u3) }
                                       { id: document-id, accessor: (element-at? accessors u4) })))
  )
)

;; Helper function for batch operations
(define-private (grant-access-helper (item { id: uint, accessor: (optional principal) }))
  (match (get accessor item)
    accessor-principal
      (map-set document-access
        { document-id: (get id item), accessor: accessor-principal }
        true)
    false)
)

;; Additional Constants
(define-constant err-already-exists (err u102))
(define-constant err-invalid-input (err u103))

;; Additional Data Maps
(define-map document-metadata
  uint
  {
    keywords: (string-ascii 200),
    category: (string-ascii 50),
    version: uint,
    citations: uint
  }
)

(define-map document-collaborators
  { document-id: uint, collaborator: principal }
  { role: (string-ascii 20), added-at: uint }
)

(define-map document-versions
  { document-id: uint, version: uint }
  { hash: (string-ascii 64), timestamp: uint, updated-by: principal }
)

;; Additional Read-only Functions
(define-read-only (get-document-metadata (document-id uint))
  (map-get? document-metadata document-id)
)

(define-read-only (get-collaborator-info (document-id uint) (collaborator principal))
  (map-get? document-collaborators { document-id: document-id, collaborator: collaborator })
)

(define-read-only (get-document-version (document-id uint) (version uint))
  (map-get? document-versions { document-id: document-id, version: version })
)

(define-read-only (is-collaborator (document-id uint) (user principal))
  (is-some (map-get? document-collaborators { document-id: document-id, collaborator: user }))
)

;; Public Functions
;; #[allow(unchecked_data)]
(define-public (add-metadata
  (document-id uint)
  (keywords (string-ascii 200))
  (category (string-ascii 50)))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (map-set document-metadata document-id
      {
        keywords: keywords,
        category: category,
        version: u1,
        citations: u0
      }
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (add-collaborator
  (document-id uint)
  (collaborator principal)
  (role (string-ascii 20)))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (asserts! (not (is-eq collaborator (get owner doc))) err-invalid-input)
    (map-set document-collaborators
      { document-id: document-id, collaborator: collaborator }
      { role: role, added-at: stacks-block-height }
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (remove-collaborator
  (document-id uint)
  (collaborator principal))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (map-delete document-collaborators { document-id: document-id, collaborator: collaborator })
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (update-document-version
  (document-id uint)
  (new-hash (string-ascii 64)))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
      (metadata (unwrap! (map-get? document-metadata document-id) err-not-found))
      (current-version (get version metadata))
      (new-version (+ current-version u1))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (asserts! (not (is-document-locked document-id)) err-document-locked)
    (map-set document-versions
      { document-id: document-id, version: new-version }
      { hash: new-hash, timestamp: stacks-block-height, updated-by: tx-sender }
    )
    (map-set document-metadata document-id
      (merge metadata { version: new-version })
    )
    (ok new-version)
  )
)

;; Additional Constants
(define-constant err-document-locked (err u104))
(define-constant err-insufficient-permissions (err u105))

;; Additional Data Maps
(define-map user-starred-documents
  { user: principal, document-id: uint }
  bool
)

(define-map document-lock-status
  uint
  { locked: bool, locked-until: uint }
)

;; Additional Data Variables
(define-data-var total-citations uint u0)
(define-data-var platform-fee uint u0)

;; Additional Read-only Functions
(define-read-only (is-document-starred (user principal) (document-id uint))
  (default-to false (map-get? user-starred-documents { user: user, document-id: document-id }))
)

(define-read-only (is-document-locked (document-id uint))
  (match (map-get? document-lock-status document-id)
    lock-info (and (get locked lock-info) (> (get locked-until lock-info) stacks-block-height))
    false
  )
)

(define-read-only (get-total-citations)
  (var-get total-citations)
)

(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

;; Public Functions
;; #[allow(unchecked_data)]
(define-public (star-document (document-id uint))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (or (get public doc) (has-access document-id tx-sender)) err-unauthorized)
    (map-set user-starred-documents
      { user: tx-sender, document-id: document-id }
      true
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (unstar-document (document-id uint))
  (begin
    (map-delete user-starred-documents { user: tx-sender, document-id: document-id })
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (increment-citations (document-id uint))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
      (metadata (unwrap! (map-get? document-metadata document-id) err-not-found))
      (current-citations (get citations metadata))
    )
    (asserts! (or (get public doc) (has-access document-id tx-sender)) err-unauthorized)
    (map-set document-metadata document-id
      (merge metadata { citations: (+ current-citations u1) })
    )
    (var-set total-citations (+ (var-get total-citations) u1))
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (lock-document (document-id uint) (lock-blocks uint))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (map-set document-lock-status document-id
      { locked: true, locked-until: (+ stacks-block-height lock-blocks) }
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (unlock-document (document-id uint))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (map-set document-lock-status document-id
      { locked: false, locked-until: u0 }
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (transfer-ownership (document-id uint) (new-owner principal))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
      (old-owner (get owner doc))
    )
    (asserts! (is-eq tx-sender old-owner) err-unauthorized)
    (asserts! (not (is-eq new-owner old-owner)) err-invalid-input)
    (asserts! (not (is-document-locked document-id)) err-document-locked)
    (map-set documents document-id (merge doc { owner: new-owner }))
    (map-set user-document-count old-owner (- (get-user-document-count old-owner) u1))
    (map-set user-document-count new-owner (+ (get-user-document-count new-owner) u1))
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (update-document-title (document-id uint) (new-title (string-ascii 100)))
  (let
    (
      (doc (unwrap! (map-get? documents document-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner doc)) err-unauthorized)
    (asserts! (not (is-document-locked document-id)) err-document-locked)
    (map-set documents document-id (merge doc { title: new-title }))
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (var-set platform-fee new-fee)
    (ok true)
  )
)