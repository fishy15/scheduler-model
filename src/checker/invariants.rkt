#lang rosette/safe

(require "../hidden/main.rkt"
         "../visible/main.rkt")

(provide invariants
         (struct-out invariant))

(struct invariant (name inv))

#|
;; the following functions are "invariants" that the scheduler should always be able to maintain

;; if there are >N tasks, no cpu should be idle
;; what does this mean from cpu A's perspective
;; \forall sd, when cpu A runs load balance it cant get any work
;; ...even though there should be enough tasks for everyone
;; return false if [theres enough work] and [im idle after all lb iters]

;; i think the way our logging works, we dont see if u were idle before
;; but it doesnt rly matter, just am i always idle after the steal
(define (right-to-work hidden visible)
  (define theres-enough-work
    (> (total-nr-tasks hidden) (hidden-state-nr-cpus hidden)))
  (define all-idle-after-balance
    (all-sd-bufs
     visible
     #:null-value #f
     (lambda (logmsg)
       (define env (lb-logmsg-lb-env logmsg))
       ;; check if env-idle is CPU_IDLE
       ;; maybe also CPU_NEWLY_IDLE? but CPU_IDLE should be good
       ;; since we want it to not transition right
       ;; fortunately we get these in string form asw
       (or (equal? (lb-env-idle env) "CPU_IDLE")
           (equal? (lb-env-idle env) "CPU_NEWLY_IDLE")))))
  ;; return false if all sd returned true
  (not (and theres-enough-work all-idle-after-balance)))
|#

;; We should not move a task from src -> dst if there is some other
;; core with 2x the util (constant can be adjusted as needed)
;; If no move happens, then return true.
(define MOVE-RATIO 2)
(define (moves-from-busiest hidden visible)
  (define (check-sd sd-info)
    (let* ([visible-sd (visible-sd-info-sd sd-info)]
           [src-cpu (visible-sd-src-cpu visible-sd)]
           [dst-cpu (visible-sd-dst-cpu visible-sd)])
      (cond
        [(not (or (eq? src-cpu 'null) (eq? dst-cpu 'null)))
         (let* ([hidden-src-cpu (hidden-get-cpu-by-id hidden src-cpu)]
                [src-util (hidden-cpu-cpu-util hidden-src-cpu)]
                [max-util (hidden-max-util hidden)])
           (implies (visible-did-tasks-move? sd-info)
                    (>= (* src-util MOVE-RATIO) max-util)))]
        [else #t])))
  (andmap check-sd (visible-state-per-sd-info visible)))

;; Checks if there exists an overloaded CPU (>= 2 tasks) and dst is idle (0 tasks)
;; then the scheduler attempts to make progress by moving some tasks
;; from an overloaded CPU to dst.
(define (create-overloaded-to-idle-check this-hidden-overloaded?)
  (define (overloaded-to-idle hidden visible)
    (define (moves-to-idle sd-info)
      (let* ([visible-sd (visible-sd-info-sd sd-info)]
             [dst-cpu (visible-sd-dst-cpu visible-sd)])
        (cond
          [(not (eq? dst-cpu 'null))
           (let* ([hidden-dst-cpu (hidden-get-cpu-by-id hidden dst-cpu)]
                  [dst-idle (hidden-cpu-idle? hidden-dst-cpu)])
             dst-idle)]
          [else #f])))
    (define (moves-idle-to-overloaded sd-info)
      (let* ([visible-sd (visible-sd-info-sd sd-info)]
             [src-cpu (visible-sd-src-cpu visible-sd)]
             [dst-cpu (visible-sd-dst-cpu visible-sd)])
        (cond
          [(not (or (eq? src-cpu 'null) (eq? dst-cpu 'null)))
           (let* ([hidden-src-cpu (hidden-get-cpu-by-id hidden src-cpu)]
                  [hidden-dst-cpu (hidden-get-cpu-by-id hidden dst-cpu)]
                  [src-overloaded (this-hidden-overloaded? hidden-src-cpu)]
                  [dst-idle (hidden-cpu-idle? hidden-dst-cpu)])
             (and src-overloaded dst-idle))]
          [else #f])))
    (let ([any-overloaded (hidden-any-cpus-overloaded? hidden)]
          [to-idle (ormap moves-to-idle (visible-state-per-sd-info visible))]
          [idle-to-overloaded (ormap moves-idle-to-overloaded (visible-state-per-sd-info visible))])
      (implies (and any-overloaded to-idle)
               idle-to-overloaded)))
  overloaded-to-idle)

(define overloaded-to-idle (create-overloaded-to-idle-check hidden-cpu-overloaded?))
(define overloaded-to-idle-cfs (create-overloaded-to-idle-check hidden-cpu-cfs-overloaded?))

;; sanity 1 -- any valid assignment fails the check
(define (sanity _hidden _visible)
  #f)

;; sanity 2 -- check that rosette can instantiate variables
(define (sanity-two hidden _visible)
  (define cpu0 (hidden-get-cpu-by-id hidden 0))
  (equal? (hidden-cpu-nr-tasks cpu0) 0))

; (define (all-invariants hidden visible)
;   (and (moves-from-busiest hidden visible)
;        (overloaded-to-idle hidden visible)))

;; Don't use moves-from-busiest --- the relationship between load and tasks is difficult to entangle
(define invariants
  (list (invariant "moves-from-busiest" moves-from-busiest)
        (invariant "overloaded-to-idle" overloaded-to-idle)
        (invariant "overloaded-to-idle-cfs" overloaded-to-idle-cfs)))
