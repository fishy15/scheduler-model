#lang racket/base

(require racket/match
         racket/cmdline
         "solve.rkt"
         "checker/main.rkt"
         "topology.rkt")

(define file (vector-ref (current-command-line-arguments) 0))
(define topology-str (vector-ref (current-command-line-arguments) 1))

(define topology
  (case topology-str
    [("16")
     (construct-topology '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]
    [("16-tiered")
     (construct-topology '((0 1 2 3) (4 5 6 7) (8 9 10 11) (12 13 14 15)))]
    [("2")
     (construct-topology '(0 1))]))

(println (format "FILE: ~a" file))
(println (format "TOPOLOGY: ~a" topology)) ;; TODO: pretty print

(for ([invariant invariants])
  (define result (solve-from-file file topology invariant))
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
