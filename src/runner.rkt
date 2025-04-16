#lang racket/base

(require "solve.rkt"
         "checker/main.rkt")

(define file (vector-ref (current-command-line-arguments) 0))

(displayln (format "FILE: ~a" file))

(define result (solve-from-file file invariants))
(cond
  [(list? result)
   (for ([inv (in-list invariants)]
         [res (in-list result)])
     (if (success? res)
         (begin
           (displayln (format "~a: FOUND COUNTEREXAMPLE" inv))
           (displayln (format "hidden: ~a" (success-hidden res)))
           (displayln (format "visible: ~a" (success-visible res))))
         (displayln (format "~a: PASSED"))))]
  [(inconsistent? result)
   (begin
     (displayln (format "INCONSISTENCY FOUND"))
     (displayln (format "visible: ~a" (inconsistent-visible result))))])