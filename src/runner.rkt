#lang racket/base

(require "solve.rkt"
         "checker/main.rkt"
         "hidden/main.rkt"
         "visible/main.rkt")

(define argv (current-command-line-arguments))

(define file (vector-ref argv 0))
(define chosen-invariants
  (if (> (vector-length argv) 1)
      (let ([inv-name (vector-ref argv 1)])
        (filter (lambda (inv) (equal? (invariant-name inv) inv-name)) invariants))
      invariants))

(displayln (format "FILE: ~a" file))

(define result (solve-from-file file chosen-invariants))

(cond
  [(list? result)
   (for ([inv (in-list invariants)]
         [res (in-list result)])
     (if (success? res)
         (begin
           (displayln (format "~a: FOUND COUNTEREXAMPLE" (success-name res)))
           (displayln (format "HIDDEN: ~a" (hidden->json-string (success-hidden res))))
           (displayln (format "VISIBLE: ~a" (visible->json-string (success-visible res)))))
         (displayln (format "~a: PASSED" inv))))]
  [(inconsistent? result)
   (begin
     (displayln "INCONSISTENCY FOUND")
     (displayln (format "CHECKS: ~a" (inconsistent-checks result)))
     (displayln (format "VISIBLE: ~a" (visible->json-string (inconsistent-visible result)))))])
