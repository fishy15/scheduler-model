#lang rosette/safe

(require "../hidden/main.rkt"
         "../visible/main.rkt")

(provide invariants)

(define (check-all-sd-bufs visible pred comb-fn null-value)
  (define (nullable-pred sd-buf)
    (let ([env (sd-entry-lb-logmsg sd-buf)])
      (if env
          (pred env)
          null-value)))
  (comb-fn nullable-pred (visible-state-sd-buf visible)))

;; Check if all of the values sd-bufs satisfy some property.
;; By default, if an sd-buf wasn't measured, it returns #t
(define (all-sd-bufs visible pred #:null-value [null-value #t])
  (check-all-sd-bufs visible pred andmap null-value))

;; Check if any of the values sd-bufs satisfy some property.
;; By default, if an sd-buf wasn't measured, it returns #f
(define (any-sd-buf visible pred #:null-value [null-value #f])
  (check-all-sd-bufs visible pred ormap null-value))

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
      (lambda (env)
        ;; check if env-idle is CPU_IDLE
        ;; maybe also CPU_NEWLY_IDLE? but CPU_IDLE should be good
        ;; since we want it to not transition right
        ;; fortunately we get these in string form asw
        (or (equal? (lb-env-idle env) "CPU_IDLE")
            (equal? (lb-env-idle env) "CPU_NEWLY_IDLE")))))
  ;; return false if all sd returned true
  (not (and theres-enough-work all-idle-after-balance)))

;; sanity 1 -- any valid assignment fails the check
(define (sanity hidden visible)
  #f)

;; sanity 2 -- check that rosette can instantiate variables
(define (sanity-two hidden visible)
  (define cpu0 (get-cpu-by-id hidden 0))
  (equal? (hidden-cpu-nr-tasks cpu0) 0))

;; Checks if there exists an overloaded CPU (>= 2 tasks) and an idle CPU (= 0 tasks),
;; then the scheduler attempts to make progress by moving some tasks
;; from an overloaded CPU to an idle CPU.
(define (overloaded-to-idle hidden visible)
  (define any-overloaded (any-cpus-overloaded? hidden))
  (define any-idle (any-cpus-idle? hidden))
  (define moves-overloaded-to-idle
    (any-sd-buf
      visible
      (lambda (env)
        (define src-cpu (lb-env-src-cpu env))
        (define dst-cpu (lb-env-dst-cpu env))
        (and (hidden-cpu-overloaded? (get-cpu-by-id hidden src-cpu))
             (hidden-cpu-idle? (get-cpu-by-id hidden dst-cpu))))))
  (implies (and any-overloaded any-idle)
           moves-overloaded-to-idle))

(define invariants (list overloaded-to-idle right-to-work))
