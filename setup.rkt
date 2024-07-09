#lang racket

(provide (all-defined-out))

;; if no argument given, then returns the number of cpus set, or #f if not set yet
;; if an argument given, sets the number of cpus to that
(define num-cpus #f)
(define cpus
  (case-lambda
    [() num-cpus]
    [(num)
     (begin
       (unless (eq? num-cpus #f)
         (raise-user-error 'cpus
                           "number of cpus has already been set"))
       (unless (exact-positive-integer? num)
         (raise-argument-error 'cpus
                               "number of cpus must be a positive integer"
                               num))
       (set! num-cpus num))]))

;; if no argument given, then returns the number of cpus set, or #f if not set yet
;; if an argument given, sets the number of cpus to that
(define num-tasks #f)
(define tasks
  (case-lambda
    [() num-tasks]
    [(num)
     (begin
       (unless (eq? num-tasks #f)
         (raise-user-error 'tasks
                           "number of tasks has already been set"))
       (unless (exact-positive-integer? num)
         (raise-argument-error 'tasks
                               "exact-positive-integer?"
                               num))
       (set! num-tasks num))]))

;; only for internal use to reset
(define (reset-state!)
  (set! num-cpus #f)
  (set! num-tasks #f))
