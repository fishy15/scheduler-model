#lang rosette/safe

(require "../hidden/main.rkt"
         "../visible/main.rkt"
         "util.rkt")

(provide valid)

;; Checks if the given hidden state could produce the given visible state
(define (valid hidden visible)
  (and (visible-cpu-nr-tasks-matches hidden visible)))
; (and (visible-cpu-nr-tasks-matches-fbq hidden visible)
;      (only-move-from-nonidle hidden visible)
;      (non-negative-tasks hidden)
;      (non-negative-load hidden)
;      (tasks-iff-positive-load hidden)
;      (group-loads-matches-visible hidden visible)
;      (group-tasks-matches-visible hidden visible)))

(define (check-all-cpus visible f)
  (define nr-cpus (visible-state-nr-cpus visible))
  (define (go cpu-id)
    (cond
      [(>= cpu-id nr-cpus) #t]
      [else (and (f cpu-id) (go (+ cpu-id 1)))]))
  (go 0))

(define (visible-cpu-nr-tasks-matches hidden visible)
  ;; the number of tasks we assign to it in hidden matches
  ;; the number of tasks it actually has in visible
  (define (check-cpu cpu-id)
    (define hidden-cpu (hidden-get-cpu-by-id hidden cpu-id))
    (define hidden-nr-tasks (hidden-cpu-nr-tasks hidden-cpu))
    (define visible-cpu (visible-state-get-cpu visible cpu-id))
    (define visible-nr-tasks (visible-cpu-info-nr-running visible-cpu))
    (displayln (format "cpu ~a has ~a ~a" cpu-id hidden-nr-tasks visible-nr-tasks))
    (eq-or-null? hidden-nr-tasks visible-nr-tasks))
  (check-all-cpus visible check-cpu))

#|
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

;; Check that for each group that we collected data on,
;; the total number of CFS tasks
;; is the sum of the individual tasks
(define (group-tasks-matches-visible hidden visible)
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
                  (define group-tasks (fbg-stat-sum-h-nr-running sgs))
                  (eq? group-tasks (group-total-nr-tasks hidden mask)))
                (fbg-logmsg-per-sg-msgs fbg-logmsg))]))))
|#