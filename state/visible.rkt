#lang racket

(struct visible-state
  ()
  #:transparent)

(define (construct-visible-state-var)
  (visible-state))

(provide construct-visible-state-var)
