#lang racket/base

(struct hidden-state
  ()
  #:transparent)

(define (construct-hidden-state-var)
  (hidden-state))

(provide construct-hidden-state-var)
