#lang racket/base

(require "solve.rkt"
         "checker/main.rkt"
         "topology.rkt")

;; (define topology (construct-topology '((0 1 2 3) (4 5 6 7) (8 9 10 11) (12 13 14 15))))
(define topology (construct-topology '(0 1 2 3)))

(for ([invariant invariants])
  (define result (solve-from-file "./visible/single.json" topology invariant)) ;; single topology is '(0 1)
  (displayln (format "~a result is ~a" invariant result)))
