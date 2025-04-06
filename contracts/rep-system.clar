(define-constant err-owner-only (err u100))
(define-constant err-same-user (err u101))
(define-constant err-invalid-reputation-amount (err u102))
(define-constant err-maximum-ratings-reached (err u103))
(define-constant err-already-made-at-this-block-height (err u104))
(define-constant err-bop (err u105))

(define-map user-reputation principal {reputation: int})
(define-map user-decay principal {last-decay: uint})
(define-map user-ratings principal {ratings: (list 200 {user: principal, amount: int, height: uint})})
(define-map received-ratings principal {ratings: (list 200 {user: principal, amount: int, height: uint})})
(define-map all-ratings-made principal {ratings: (list 200 {user: principal, amount: int, height: uint})})

(define-public (rate-user (user-to-rate principal) (reputation-amount int))
  (begin
    (asserts! (not (is-eq tx-sender user-to-rate)) err-same-user)
    (let
      (
        (user-to-rate-reputation (default-to 0 (get-user-reputation user-to-rate)))
        (existing-data (default-to {ratings: (list)} (map-get? user-ratings tx-sender)))
        (existing-received-data (default-to {ratings: (list)} (map-get? received-ratings user-to-rate)))
        (existing-all-ratings (default-to {ratings: (list)} (map-get? all-ratings-made tx-sender)))
        (new-rating {user: user-to-rate, amount: reputation-amount, height: stacks-block-height})
        (new-received-rating {user: tx-sender, amount: reputation-amount, height: stacks-block-height})
      )
      (asserts! (and 
                  (>= reputation-amount (if (>= (default-to 0 (get-user-reputation tx-sender)) 50) -20 -10))
                  (<= reputation-amount (if (>= (default-to 0 (get-user-reputation tx-sender)) 50) 20 10))
                  (>= (+ user-to-rate-reputation reputation-amount) -100) 
                  (<= (+ user-to-rate-reputation reputation-amount) 100)) 
                err-invalid-reputation-amount)
      (match (get-rated-height user-to-rate)
        height 
          (begin
            (asserts! (>= stacks-block-height (+ height u1000)) err-already-made-at-this-block-height)
            (let 
              (
                (idx (unwrap! (find-index user-to-rate) err-bop))
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

;; This proved to be very ineficiently if it were to be used on every contract call (get-user-reputation/ rate-user)
(define-public (optional-decay-reputation (user principal))
  (let 
    (
      (last-decay (default-to u0 (get last-decay (map-get? user-decay user)))) 
      (decay-periods (/ (- stacks-block-height last-decay) u1000))
      (current-rep (default-to 0 (get reputation (map-get? user-reputation user))))
    )
    (print last-decay)
    (print decay-periods)
    (print current-rep)
    (if (or 
          (is-eq decay-periods u0)
          (< stacks-block-height u1000)
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


