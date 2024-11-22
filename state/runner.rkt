#lang racket/base

(require "solve.rkt"
         "checker.rkt"
         "topology.rkt")

(displayln (list? invariants))
(define topology (construct-topology '(0 1)))

(for ([invariant invariants])
  (displayln (solve-from-file "single.json" topology invariant)))
