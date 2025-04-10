#lang racket/base

(require racket/match
         racket/cmdline
         "solve.rkt"
         "checker/main.rkt"
         "topology.rkt")

(define file (vector-ref (current-command-line-arguments) 0))

(displayln (format "FILE: ~a" file))

(for ([invariant invariants])
  (define result (solve-from-file file invariant))
  (match result
    [#f (displayln (format "~a: FAILED" invariant))]
    [(cons hidden visible)
     (begin
       (displayln (format "~a: FOUND COUNTEREXAMPLE" invariant))
       (displayln (format "hidden: ~a" hidden))
       (displayln (format "visible: ~a" visible)))]
    [visible
     (begin
       (displayln (format "~a: FOUND COUNTEREXAMPLE" invariant))
       (displayln (format "visible: ~a" visible)))]))
