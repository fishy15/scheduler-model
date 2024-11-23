#lang rosette/safe

(require "hidden.rkt"
         "visible.rkt")

;; Checks if the given hidden state could produce the given visible state
(define (valid hidden visible)
  (and (visible-cpu-nr-tasks-matches-fbq hidden visible)
       (only-move-from-nonidle hidden visible)))

(define (visible-cpu-nr-tasks-matches-fbq hidden visible)
  ;; for all cpus visited by fbq, check that
  ;; the number of tasks we assign to it in hidden matches
  ;; the number of tasks it actually has in visible
  #t)
  
(define (only-move-from-nonidle hidden visible)
  ;; Currently only nr-tasks is defined for the visible state,
  ;; so we need to find for which CPUs we know the number of tasks
  ;; and force it to be equal.
  ;; We don't have this information currently,
  ;; instead we will check if we move a task from a CPU, it has >0 tasks.
  (define (check-sd-buf sd-buf)
    (define env (sd-entry-lb-logmsg sd-buf))
    (if env
        (begin
          (define src-cpu (lb-env-src-cpu env))
          (> (hidden-cpu-nr-tasks (get-cpu-by-id visible src-cpu)) 0))
        #t))
  (andmap check-sd-buf (visible-state-sd-buf visible)))

;; the following functions are "invariants" that the scheduler should always be able to maintain

;; if there are >N tasks, no cpu should be idle
;; what does this mean from cpu A's perspective
;; \forall sd, when cpu A runs load balance it cant get any work
;; ...even though there should be enough tasks for everyone
;; return false if [theres enough work] and [im idle after all lb iters]

;; i think the way our logging works, we dont see if u were idle before
;; but it doesnt rly matter, just am i always idle after the steal
(define (right-to-work hidden visible)
  (define theres-enough-work (> (total-nr-tasks hidden) (hidden-state-nr-cpus hidden)))

  ;; lb is run per sd
  ;; foreach sd, check im idle after lb
  ;; if so return true else return false
  (define (idle-after-balance-sd sd-buf)
    (begin
      (define env (sd-entry-lb-logmsg sd-buf))
      ;; check if env-idle is CPU_IDLE
      ;; maybe also CPU_NEWLY_IDLE? but CPU_IDLE should be good
      ;; since we want it to not transition right
      ;; fortunately we get these in string form asw
      (or (equal? (lb-env-idle env) "CPU_IDLE")
          (equal? (lb-env-idle env) "CPU_NEWLY_IDLE"))))

  ;; return false if all sd returned true
  (not (and theres-enough-work
            (andmap idle-after-balance-sd (visible-state-sd-buf visible)))))

;; sanity two--check that rosette can instantiate variables
(define (san2 hidden visible)
  (define cpu0 (get-cpu-by-id hidden 0))
  (equal? (hidden-cpu-nr-tasks cpu0) 0))

(define (sanity hidden visible)
  #f)

;; Checks if there exists an overloaded CPU (>= 2 tasks) and an idle CPU (= 0 tasks),
;; then the scheduler attempts to make progress by moving some tasks
;; from an overloaded CPU to an idle CPU.
(define (overloaded-to-idle hidden visible)
  (define any-overloaded (any-cpus-overloaded? hidden))
  (define any-idle (any-cpus-idle? hidden))
  (if (and any-overloaded any-idle)
      (begin
        ;; Checks if it moves overloaded -> idle in this sd-buf iteration
        (define (check-sd-buf sd-buf)
          (define env (sd-entry-lb-logmsg sd-buf))
          (if env
              (begin
                (define src-cpu (lb-env-src-cpu env))
                (define dst-cpu (lb-env-dst-cpu env))
                (and (hidden-cpu-overloaded? (get-cpu-by-id hidden src-cpu))
                     (hidden-cpu-idle? (get-cpu-by-id hidden dst-cpu))))
              #f))
        (ormap check-sd-buf (visible-state-sd-buf visible)))
      #t))

(define invariants (list overloaded-to-idle right-to-work))
(provide valid invariants)
