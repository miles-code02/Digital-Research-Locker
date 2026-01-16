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