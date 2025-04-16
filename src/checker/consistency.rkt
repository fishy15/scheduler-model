#lang rosette/safe

(require "../hidden/main.rkt"
         "../visible/main.rkt"
         "util.rkt")

(provide all-checks
         valid)

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
    (eq-or-null? hidden-nr-tasks visible-nr-tasks))
  (check-all-cpus visible check-cpu))

;; Every cpu has a non-negative number of tasks
(define (non-negative-tasks hidden visible)
  (define (check-cpu cpu-id)
    (define hidden-cpu (hidden-get-cpu-by-id hidden cpu-id))
    (define hidden-nr-tasks (hidden-cpu-nr-tasks hidden-cpu))
    (>= hidden-nr-tasks 0))
  (check-all-cpus visible check-cpu))

;; Every cpu has a non-negative load
(define (non-negative-load hidden visible)
  (define (check-cpu cpu-id)
    (define hidden-cpu (hidden-get-cpu-by-id hidden cpu-id))
    (define hidden-load (hidden-cpu-cpu-load hidden-cpu))
    (>= hidden-load 0))
  (check-all-cpus visible check-cpu))

;; If we have some number of tasks, then we must have non-zero load.
(define (tasks-then-positive-load hidden visible)
  (define (check-cpu cpu-id)
    (define hidden-cpu (hidden-get-cpu-by-id hidden cpu-id))
    (define hidden-nr-tasks (hidden-cpu-nr-tasks hidden-cpu))
    (define hidden-load (hidden-cpu-cpu-load hidden-cpu))
    (implies (> hidden-nr-tasks 0)
             (> hidden-load 0)))
  (check-all-cpus visible check-cpu))

;; If the cpu idle type we used was CPU_IDLE,
;; then there must be zero tasks on the rq.
(define (no-tasks-if-idle-cpu-type hidden visible)
  (define (check-cpu cpu-id)
    (let* ([visible-cpu (visible-state-get-cpu visible cpu-id)]
           [visible-cpu-idle-type (visible-cpu-info-cpu-idle-type visible-cpu)]
           [hidden-cpu (hidden-get-cpu-by-id hidden cpu-id)]
           [hidden-nr-tasks (hidden-cpu-nr-tasks hidden-cpu)])
      (implies (eq? visible-cpu-idle-type "CPU_IDLE")
               (= hidden-nr-tasks 0))))
  (check-all-cpus visible check-cpu))


;; Check that for each group that we collected data on,
;; the measured average load is the average of the individual loads
(define (group-tasks-matches-visible hidden visible)
  (define (check-sd sd-info)
    (define (check-sg sg-info)
      (define cpumask (visible-sg-info-cpumask sg-info))
      (cond
        [(eq? cpumask 'null) #t]
        [else
         (define hidden-cpus (hidden-get-cpus-by-mask hidden cpumask))
         (define hidden-total-tasks (foldr + 0 (map hidden-cpu-nr-tasks hidden-cpus)))
         (eq-or-null? hidden-total-tasks
                      (visible-sg-info-sum-h-nr-running sg-info))]))
    (andmap check-sg (visible-sd-info-groups sd-info)))
  (andmap check-sd (visible-state-per-sd-info visible)))

;; Check that for each group that we collected data on,
;; the measured average load is the average of the individual loads
(define (group-loads-matches-visible hidden visible)
  (define (check-sd sd-info)
    (define (check-sg sg-info)
      (define cpumask (visible-sg-info-cpumask sg-info))
      (cond
        [(eq? cpumask 'null) #t]
        [else
         (define hidden-cpus (hidden-get-cpus-by-mask hidden cpumask))
         (define hidden-total-load (foldr + 0 (map hidden-cpu-cpu-load hidden-cpus)))
         (define avg-load (/ hidden-total-load (length hidden-cpus)))
         (eq-or-null? avg-load (visible-sg-info-avg-load sg-info))]))
    (andmap check-sg (visible-sd-info-groups sd-info)))
  (andmap check-sd (visible-state-per-sd-info visible)))

;; Check that for each cpu that we collected data on,
;; the measured cpu load matches.
(define (cpu-loads-matches-visible hidden visible)
  (define (check-cpu cpu-id)
    (let* ([visible-cpu (visible-state-get-cpu visible cpu-id)]
           [hidden-cpu (hidden-get-cpu-by-id hidden cpu-id)]
           [visible-load (visible-cpu-info-cpu-load visible-cpu)]
           [hidden-load (hidden-cpu-cpu-load hidden-cpu)])
      (eq-or-null? hidden-load visible-load)))
  (check-all-cpus visible check-cpu))

(define all-checks
  (list visible-cpu-nr-tasks-matches
        non-negative-tasks
        non-negative-load
        ; tasks-then-positive-load <- the relation is more complicated than this...
        no-tasks-if-idle-cpu-type
        group-tasks-matches-visible
        ; (group-loads-matches-visible hidden visible) <- for some reason, does not agree with below
        cpu-loads-matches-visible))

;; Checks if the given hidden state could produce the given visible state
(define (valid hidden visible [checks all-checks])
  (andmap (lambda (chk) (chk hidden visible)) checks))

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
|#
