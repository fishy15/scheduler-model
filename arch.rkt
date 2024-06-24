#lang racket

(require "setup.rkt")

(struct cpu (num)
  #:guard (lambda (num name)
            (when (equal? #f (cpus))
              (raise-argument-error 'cpu "number of cpus has not been set"))
            (unless (and (<= 0 num) (< num (cpus)))
              (raise-argument-error 'cpu "cpu number is invalid"))))

(provide (struct-out cpu))

