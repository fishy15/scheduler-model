#lang racket/base

(require "solve.rkt"
         "checker.rkt"
         "topology.rkt")

(displayln (list? invariants))
(define topology (construct-topology '((0 1 2 3) (4 5 6 7) (8 9 10 11) (12 13 14 15))))

(for ([invariant invariants])
  (displayln (solve-from-file "../../data2.json" topology invariant)))
