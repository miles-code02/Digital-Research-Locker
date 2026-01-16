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