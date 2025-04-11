#lang racket/base

(require racket/match
         "solve.rkt"
         "checker/main.rkt")

(define file (vector-ref (current-command-line-arguments) 0))

(displayln (format "FILE: ~a" file))

(for ([invariant invariants])
  (define result (solve-from-file file invariant))
  (match result
    [(success hidden visible)
     (begin
       (displayln (format "~a: FOUND COUNTEREXAMPLE" invariant))
       (displayln (format "hidden: ~a" hidden))
       (displayln (format "visible: ~a" visible)))]
    [(inconsistent visible)
     (begin
       (displayln (format "INCONSISTENCY FOUND"))
       (displayln (format "visible: ~a" visible)))]
    [_ (displayln (format "~a: FAILED" invariant))]))
