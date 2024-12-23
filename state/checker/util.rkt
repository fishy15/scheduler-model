#lang rosette/safe

(require "../visible/main.rkt")

(provide eq-or-null?
         all-sd-bufs
         any-sd-buf)

(define (eq-or-null? hidden visible)
  (or (eq? visible 'null) (eq? hidden visible)))

(define (check-all-sd-bufs visible pred comb-fn null-value)
  (define (nullable-pred sd-buf)
    (let ([env (sd-entry-lb-logmsg sd-buf)])
      (if env
          (pred env)
          null-value)))
  (comb-fn nullable-pred (visible-state-sd-buf visible)))

;; Check if all of the values sd-bufs satisfy some property.
;; By default, if an sd-buf wasn't measured, it returns #t
(define (all-sd-bufs visible pred #:null-value [null-value #t])
  (check-all-sd-bufs visible pred andmap null-value))

;; Check if any of the values sd-bufs satisfy some property.
;; By default, if an sd-buf wasn't measured, it returns #f
(define (any-sd-buf visible pred #:null-value [null-value #f])
  (check-all-sd-bufs visible pred ormap null-value))
