#lang racket

(require
  rackunit
  "setup.rkt"
  "arch.rkt"
  (only-in "setup-test.rkt" test-with-default))

(test-with-default
  (cpus 10)
  (for ([num '(-1 0 10 11 'abc)])
    (check-exn exn:fail? (lambda () (cpu -1)))))
