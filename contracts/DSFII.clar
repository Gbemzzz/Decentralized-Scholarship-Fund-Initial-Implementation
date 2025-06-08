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

          (map-set donors { donor: tx-sender } { total-donated: new-total }))
        (map-set donors { donor: tx-sender } { total-donated: amount })))
    (let ((new-fund (try! (safe-add (var-get total-scholarship-fund) amount))))
      (var-set total-scholarship-fund new-fund)
      (ok true))
  )
)

;; Public Function: Apply for Scholarship
(define-public (apply-scholarship (amount-requested uint) (reason (string-utf8 500)))
  (begin
    (asserts! (validate-amount amount-requested) err-invalid-amount)
    (asserts! (validate-reason reason) err-invalid-reason)
    (asserts! (> (var-get total-scholarship-fund) u0) err-application-closed)
    (let ((existing-application (map-get? applicants { student: tx-sender })))
      (asserts! (is-none existing-application) err-already-applied)
      (map-set applicants { student: tx-sender } { status: "pending", amount-requested: amount-requested, reason: reason })
      (ok true)
    )
  )
)

;; Public Function: Evaluate Application
(define-public (evaluate-application (student principal) (approve bool))
  (begin
    (asserts! (is-owner) err-not-owner)
    (asserts! (validate-principal student) err-invalid-principal)
    (let ((application (map-get? applicants { student: student })))
      (asserts! (is-some application) err-not-found)
      (let ((application-data (unwrap! application err-not-found)))
        (if approve
          (begin
            (let ((requested (get amount-requested application-data)))
              (asserts! (>= (var-get total-scholarship-fund) requested) err-insufficient-funds)
              (try! (ft-transfer? scholarship-token requested (var-get owner) student))
              (map-set applicants { student: student } { status: "approved", amount-requested: requested, reason: (get reason application-data) })
              (var-set total-scholarship-fund (- (var-get total-scholarship-fund) requested))
              (ok true)
            )
          )


          (begin
            (map-set applicants { student: student } { status: "rejected", amount-requested: (get amount-requested application-data), reason: (get reason application-data) })
            (ok false)
          )
        )
      )
    )
  )
)

;; Public Function: Get Application Status
(define-read-only (get-application-status (student principal))
  (match (map-get? applicants { student: student })
    application (ok (get status application))
    (err err-not-found)
  )
)
;; New Constants and Maps
(define-constant max-category-length u50)
(define-map earmarked-funds { category: (string-ascii 50) } { amount: uint })
(define-map donor-earmarks { donor: principal, category: (string-ascii 50) } { amount: uint })

;; Private Function: Validate Category
(define-private (validate-category (category (string-ascii 50)))
  (and (> (len category) u0) (<= (len category) max-category-length))
)

;; Public Function: Donate with Earmark
(define-public (donate-earmarked (amount uint) (category (string-ascii 50)))
  (begin
    (asserts! (validate-amount amount) err-invalid-amount)
    (asserts! (validate-category category) (err u109))
    (try! (ft-transfer? scholarship-token amount tx-sender (var-get owner)))
    (ok true)
  )
)
(define-read-only (get-earmarked-amount (category (string-ascii 50)))
  (match (map-get? earmarked-funds { category: category })
    earmark (ok (get amount earmark))
    (err err-not-found)
  )
)

(define-read-only (get-donor-earmarked-amount (donor principal) (category (string-ascii 50)))
  (match (map-get? donor-earmarks { donor: donor, category: category })
    earmark (ok (get amount earmark))
    (err err-not-found)
  )
)
