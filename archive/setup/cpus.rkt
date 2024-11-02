#lang racket

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

(define (reset-cpu-state!)
  (set! num-cpus #f))

(provide cpus
         reset-cpu-state!)