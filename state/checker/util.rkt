#lang rosette/safe

(provide eq-or-null?)

(define (eq-or-null? hidden visible)
  (or (eq? visible 'null) (eq? hidden visible)))
