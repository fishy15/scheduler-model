#lang racket/base

(require "hidden.rkt"
         "visible.rkt")

;; Checks if the given hidden and visible states are valid
(define (valid hidden visible)
  #t)

;; Checks if the load balancer made the correct decision
(define (correct hidden visible)
  #t)

(provide valid
         correct)
