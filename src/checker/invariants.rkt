#lang rosette/safe

(require (only-in racket/match match)
         "../hidden/main.rkt"
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

;; If there are more tasks cores, then we want distribute tasks
(define (right-to-work hidden visible [ignore-swb #t])
  (define (check-sd sd-info)
    (let* ([visible-sd (visible-sd-info-sd sd-info)]
           [src-cpu (visible-sd-src-cpu visible-sd)]
           [dst-cpu (visible-sd-dst-cpu visible-sd)]
           [tasks-moved
            (match (visible-sd-nr-tasks-moved visible-sd)
              ['null 0]
              [x x])]
           [should-we-balance
            (match (visible-sd-should-we-balance visible-sd)
              ['null #f]
              [x x])]
           [hidden-cpus (hidden-state-cpus hidden)]
           [hidden-old-has-tasks (lambda (cpu) (> (hidden-cpu-nr-tasks cpu) 0))]
           [old-cpus-with-tasks (length (filter hidden-old-has-tasks hidden-cpus))]
           [hidden-new-has-tasks
            (lambda (cpu)
              (let ([nr-tasks (hidden-cpu-nr-tasks cpu)]
                    [cpu-id (hidden-cpu-cpu-id cpu)])
                (cond
                  [(eq? cpu-id src-cpu) (> (- nr-tasks tasks-moved) 0)]
                  [(eq? cpu-id dst-cpu) (> (+ nr-tasks tasks-moved) 0)]
                  [else (> nr-tasks 0)])))]
           [new-cpus-with-tasks (length (filter hidden-new-has-tasks hidden-cpus))])
      ;; run the check if we ignore-swb value or should-we-balance is set
      (implies (or ignore-swb should-we-balance)
               (<= old-cpus-with-tasks new-cpus-with-tasks))))
  (andmap check-sd (visible-state-per-sd-info visible)))

;; We should not move a task from src -> dst if there is some other
;; core with 2x the util (constant can be adjusted as needed)
;; If no move happens, then return true.
(define MOVE-RATIO 2)
(define (moves-from-busiest hidden visible [ignore-swb #t])
  (define (check-sd sd-info)
    (let* ([visible-sd (visible-sd-info-sd sd-info)]
           [src-cpu (visible-sd-src-cpu visible-sd)]
           [dst-cpu (visible-sd-dst-cpu visible-sd)]
           [should-we-balance
            (match (visible-sd-should-we-balance visible-sd)
              ['null #f]
              [x x])])
      (cond
        ;; if ignore-swb is false and we didn't run should we balance, then ignore
        [(and (not ignore-swb) (not should-we-balance)) #t]
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
  (define (overloaded-to-idle hidden visible [ignore-swb #t])
    (define (swb-is-true sd-info)
      (let* ([sd (visible-sd-info-sd sd-info)]
             [should-we-balance (visible-sd-should-we-balance sd)])
        (or ignore-swb should-we-balance)))
    (define sd-infos-with-swb
      (filter swb-is-true (visible-state-per-sd-info visible)))
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
          [to-idle (ormap moves-to-idle sd-infos-with-swb)]
          [idle-to-overloaded (ormap moves-idle-to-overloaded sd-infos-with-swb)])
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
  (list (invariant "right-to-work" right-to-work)
        (invariant "right-to-work-swb" (lambda (h v) (right-to-work h v #f)))
        (invariant "moves-from-busiest" moves-from-busiest)
        (invariant "moves-from-busiest-swb" (lambda (h v) (moves-from-busiest h v #f)))
        (invariant "overloaded-to-idle" overloaded-to-idle)
        (invariant "overloaded-to-idle-swb" (lambda (h v) (overloaded-to-idle h v #f)))
        (invariant "overloaded-to-idle-cfs" overloaded-to-idle-cfs)
        (invariant "overloaded-to-idle-cfs-swb" (lambda (h v) (overloaded-to-idle-cfs h v #f)))))
