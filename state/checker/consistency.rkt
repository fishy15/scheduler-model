#lang rosette/safe

(require "../hidden/main.rkt"
         "../visible/main.rkt"
         "util.rkt")

(provide valid)

;; Checks if the given hidden state could produce the given visible state
(define (valid hidden visible)
  (and (visible-cpu-nr-tasks-matches-fbq hidden visible)
       (only-move-from-nonidle hidden visible)
       (non-negative-tasks hidden)
       (non-negative-load hidden)
       (tasks-iff-positive-load hidden)
       (group-loads-matches-visible hidden visible)))

(define (visible-cpu-nr-tasks-matches-fbq hidden visible)
  ;; for all cpus visited by fbq, check that
  ;; the number of tasks we assign to it in hidden matches
  ;; the number of tasks it actually has in visible
  (define (check-pclm pclm)
    (define cpu-id (fbq-per-cpu-logmsg-cpu-id pclm))
    (eq-or-null? (hidden-cpu-nr-tasks (get-cpu-by-id hidden cpu-id))
                 (fbq-per-cpu-logmsg-rq-cfs-h-nr-running pclm)))

  (define (check-sd-buf sd-buf)
    (define lb-logmsg (sd-entry-lb-logmsg sd-buf))
    (or (false? lb-logmsg)
        (begin
          (define fbq (lb-logmsg-fbq-logmsg lb-logmsg))
          (if fbq
              (andmap check-pclm (fbq-logmsg-per-cpu-msgs fbq))
              #t))))

  (andmap check-sd-buf (visible-state-sd-buf visible)))

(define (only-move-from-nonidle hidden visible)
  ;; Currently only nr-tasks is defined for the visible state,
  ;; so we need to find for which CPUs we know the number of tasks
  ;; and force it to be equal.
  ;; We don't have this information currently,
  ;; instead we will check if we move a task from a CPU, it has >0 tasks.
  (define (check-sd-buf sd-buf)
    (define lb-logmsg (sd-entry-lb-logmsg sd-buf))
    (or (false? lb-logmsg)
        (begin
          (define env (lb-logmsg-lb-env lb-logmsg))
          (if env
              (begin
                (define src-cpu (lb-env-src-cpu env))
                (> (hidden-cpu-nr-tasks (get-cpu-by-id hidden src-cpu)) 0))
              #t))))
  (andmap check-sd-buf (visible-state-sd-buf visible)))

;; Number of tasks on each core is non-negative
(define (non-negative-tasks hidden)
  (andmap (lambda (cpu)
            (>= (hidden-cpu-nr-tasks cpu) 0))
          (hidden-state-cpus hidden)))

;; Number of tasks on each core is non-negative
(define (non-negative-load hidden)
  (andmap (lambda (cpu)
            (>= (hidden-cpu-cpu-load cpu) 0))
          (hidden-state-cpus hidden)))

;; If we have some number of tasks, then we must have non-zero load.
;; Similarly, if we have no tasks, then we have 0 load.
(define (tasks-iff-positive-load hidden)
  (andmap (lambda (cpu)
            (equal? (> (hidden-cpu-nr-tasks cpu) 0)
                    (> (hidden-cpu-cpu-load cpu) 0)))
          (hidden-state-cpus hidden)))

;; Check that for each group that we collected data on,
;; the total load is the sum of the individual loads
(define (group-loads-matches-visible hidden visible)
  (all-sd-bufs
   visible
   (lambda (lb-logmsg)
     (define fbg-logmsg (lb-logmsg-fbg-logmsg lb-logmsg))
     (cond
       [(false? fbg-logmsg) #t]
       [else
        (andmap (lambda (update-stats)
                  (define mask (update-stats-per-sg-logmsg-cpus update-stats))
                  (define sgs (update-stats-per-sg-logmsg-sgs update-stats))
                  (define group-load (fbg-stat-group-load sgs))
                  (eq? group-load (group-total-load hidden mask)))
                (fbg-logmsg-per-sg-msgs fbg-logmsg))]))))