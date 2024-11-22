#lang racket/base

(require "solve.rkt"
         "topology.rkt")

(define topology (construct-topology '(0 1)))
(displayln (solve-from-file "single.json" topology))
