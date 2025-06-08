;; Decentralized Scholarship Fund - Initial Implementation
;; Constants
(define-constant err-not-owner (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-applied (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-application-closed (err u104))
(define-constant err-arithmetic-error (err u105))
(define-constant err-invalid-amount (err u106))
(define-constant err-invalid-reason (err u107))
(define-constant err-invalid-principal (err u108))
;; Fungible Token for donations
(define-fungible-token scholarship-token)

;; Data Maps
(define-map donors { donor: principal } { total-donated: uint })
(define-map applicants { student: principal } { status: (string-ascii 10), amount-requested: uint, reason: (string-utf8 500) })
;; Variables
(define-data-var total-scholarship-fund uint u0)
(define-data-var owner principal tx-sender)

;; Private Functions
(define-private (is-owner)
  (is-eq tx-sender (var-get owner))
)

(define-private (safe-add (a uint) (b uint))
  (let ((result (+ a b)))
    (if (< result a)
      err-arithmetic-error
      (ok result))
  )
)
(define-private (validate-amount (amount uint))
  (> amount u0)
)

(define-private (validate-reason (reason (string-utf8 500)))
  (and (> (len reason) u0) (<= (len reason) u500))
)(define-private (validate-principal (principal-input principal))
  (is-eq principal-input principal-input)
)

;; Public Function: Donate
(define-public (donate (amount uint))
  (begin
    (asserts! (validate-amount amount) err-invalid-amount)
    (try! (ft-transfer? scholarship-token amount tx-sender (var-get owner)))
    (let ((existing-donation (map-get? donors { donor: tx-sender })))
      (if (is-some existing-donation)
        (let (
          (donation-data (unwrap-panic existing-donation))
          (new-total (try! (safe-add (get total-donated donation-data) amount)))
        )


