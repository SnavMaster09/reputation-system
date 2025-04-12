;; Reputation System Contract
;; This contract implements a reputation system where users can rate each other
;; within certain bounds and with decay over time.

;; Error codes
;; Validation errors (100-199)
(define-constant err-owner-only (err u100))
(define-constant err-same-user (err u101))
(define-constant err-invalid-reputation-amount (err u102))
(define-constant err-maximum-ratings-reached (err u103))
(define-constant err-already-rated-recently (err u104))
(define-constant err-invalid-operation (err u105))

;; System constants
(define-constant MIN_REPUTATION -100)
(define-constant MAX_REPUTATION 100)
(define-constant DECAY_PERIOD u1000)
(define-constant MAX_RATINGS u200)
(define-constant INITIAL_BLOCKS u1000)

(define-map user-reputation principal {reputation: int})
(define-map user-decay principal {last-decay: uint})
(define-map user-ratings principal {ratings: (list 200 {user: principal, amount: int, height: uint})})
(define-map received-ratings principal {ratings: (list 200 {user: principal, amount: int, height: uint})})
(define-map all-ratings-made principal {ratings: (list 200 {user: principal, amount: int, height: uint})})

;; Rate another user's reputation
;; @param user-to-rate: The principal to rate
;; @param reputation-amount: The amount of reputation to give/take (-20 to 20)
;; @returns: The updated reputation of the rated user
(define-public (rate-user (user-to-rate principal) (reputation-amount int))
  (begin
    ;; Validate user is not rating themselves
    (asserts! (not (is-eq tx-sender user-to-rate)) err-same-user)
    
    (let
      (
        (user-to-rate-reputation (default-to 0 (get-user-reputation user-to-rate)))
        (rater-reputation (default-to 0 (get-user-reputation tx-sender)))
        (existing-data (default-to {ratings: (list)} (map-get? user-ratings tx-sender)))
        (existing-received-data (default-to {ratings: (list)} (map-get? received-ratings user-to-rate)))
        (existing-all-ratings (default-to {ratings: (list)} (map-get? all-ratings-made tx-sender)))
        (new-rating {user: user-to-rate, amount: reputation-amount, height: stacks-block-height})
        (new-received-rating {user: tx-sender, amount: reputation-amount, height: stacks-block-height})
        (min-allowed (if (>= rater-reputation 50) -20 -10))
        (max-allowed (if (>= rater-reputation 50) 20 10))
        (new-total-reputation (+ user-to-rate-reputation reputation-amount))
      )
      ;; Validate reputation amount and bounds
      (asserts! (and 
                  (>= reputation-amount min-allowed)
                  (<= reputation-amount max-allowed)
                  (>= new-total-reputation MIN_REPUTATION) 
                  (<= new-total-reputation MAX_REPUTATION)) 
                err-invalid-reputation-amount)

      (match (get-rated-height user-to-rate)
        height 
          (begin
            (asserts! (>= stacks-block-height (+ height u1000)) err-already-rated-recently)
            (let 
              (
                (idx (unwrap! (find-index user-to-rate) err-invalid-operation))
                (current-ratings (get ratings existing-data))
                (previous-rating (unwrap! (element-at? current-ratings idx) err-maximum-ratings-reached))
              )
              (map-set user-ratings tx-sender {ratings: 
                (default-to current-ratings (replace-at? current-ratings idx new-rating))})
              (map-set received-ratings user-to-rate {ratings: 
                (default-to (get ratings existing-received-data) (replace-at? (get ratings existing-received-data) idx new-received-rating))})
              (map-set user-reputation user-to-rate {reputation: 
                (+ (- user-to-rate-reputation (get amount previous-rating)) reputation-amount)})
              (map-set all-ratings-made tx-sender {ratings:
                (unwrap! (as-max-len? (concat (get ratings existing-all-ratings) (list new-rating)) u200) 
                err-maximum-ratings-reached)}))
            )
        (begin 
          (map-set user-ratings tx-sender {ratings:
            (unwrap! (as-max-len? (concat (get ratings existing-data) (list new-rating)) u200) 
            err-maximum-ratings-reached)})
          (map-set received-ratings user-to-rate {ratings: (unwrap! (as-max-len? 
            (concat (get ratings existing-received-data) (list new-received-rating)) u200) 
            err-maximum-ratings-reached)})
          (map-set user-reputation user-to-rate {reputation: (+ user-to-rate-reputation reputation-amount)})
          (map-set all-ratings-made tx-sender {ratings:
            (unwrap! (as-max-len? (concat (get ratings existing-all-ratings) (list new-rating)) u200) 
            err-maximum-ratings-reached)})
        )
      )
      (ok (map-get? user-reputation user-to-rate))
    )
  )
)

;; Apply reputation decay if enough time has passed
;; @param user: The principal whose reputation should be decayed
;; @returns: The updated reputation after decay
(define-public (optional-decay-reputation (user principal))
  (let 
    (
      (last-decay (default-to u0 (get last-decay (map-get? user-decay user)))) 
      (decay-periods (/ (- stacks-block-height last-decay) DECAY_PERIOD))
      (current-rep (default-to 0 (get reputation (map-get? user-reputation user))))
    )
    (if (or 
          (is-eq decay-periods u0)
          (< stacks-block-height INITIAL_BLOCKS)
          (<= current-rep 0))
      (begin 
        (map-set user-decay user {last-decay: stacks-block-height})
        (ok current-rep)
      )
      (begin
        (map-set user-decay user {last-decay: stacks-block-height})
        (map-set user-reputation user {reputation: (- current-rep (/ current-rep 10))})
        (ok (- current-rep (/ current-rep 10))))
    )
  )
)

(define-private (get-user-reputation-wd (user principal)) 
  (begin
    (unwrap-panic (optional-decay-reputation user))
    (ok (default-to 0 (get reputation (map-get? user-reputation user))))
  )
)

(define-read-only (get-user-reputation (user principal)) 
  (get reputation (map-get? user-reputation user))
)

(define-read-only (get-ratings-made (user principal)) 
  (default-to {ratings: (list)} (map-get? user-ratings user))
)

(define-read-only (get-ratings-received (user principal)) 
  (default-to {ratings: (list)} (map-get? received-ratings user))
)

(define-read-only (get-rated-height (user-to-rate principal))
  (let 
    ((ratings (get ratings (default-to {ratings: (list)} (map-get? user-ratings tx-sender)))))
    (match (index-of (map get-user ratings) user-to-rate)
      index (some (unwrap! (get height (element-at? ratings index)) none))
      none
    )
  )
)

(define-private (get-user (rating {user: principal, amount: int, height: uint}))
  (get user rating)
)

(define-read-only (find-index (user-to-rate principal))
  (let ((ratings (get ratings (default-to {ratings: (list)} (map-get? user-ratings tx-sender)))))
    (index-of (map get-user ratings) user-to-rate)
  )
)

(define-read-only (get-all-ratings-made (user principal)) 
  (default-to {ratings: (list)} (map-get? all-ratings-made user))
)


