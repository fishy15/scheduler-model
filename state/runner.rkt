#lang racket/base

(require racket/match
         "solve.rkt"
         "checker/main.rkt"
         "topology.rkt")

(define file "many-16-tiered.json")
(define topology (construct-topology '((0 1 2 3) (4 5 6 7) (8 9 10 11) (12 13 14 15))))
;; (define topology (construct-topology '(0 1)))

(for ([invariant invariants])
  (define result (solve-from-file file topology invariant))
  (match result
    [(cons hidden visible)
     (begin
       (displayln (format "~a" invariant))
       (displayln (format "hidden: ~a" hidden))
       (displayln (format "visible: ~a" visible)))]
    [else (displayln (format "~a: FAILED" invariant))]))
