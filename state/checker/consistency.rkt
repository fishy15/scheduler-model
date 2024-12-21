#lang rosette/safe

(require "../hidden/main.rkt"
         "../visible/main.rkt")

(provide valid)

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
          (> (hidden-cpu-nr-tasks (get-cpu-by-id hidden src-cpu)) 0))
        #t))
  (andmap check-sd-buf (visible-state-sd-buf visible)))
