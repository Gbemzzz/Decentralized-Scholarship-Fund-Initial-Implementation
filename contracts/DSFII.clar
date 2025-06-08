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
