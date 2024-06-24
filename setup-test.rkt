#lang racket

(require rackunit "setup.rkt")

;; runs a test starting from the default state
(define-syntax-rule (test-with-default body ...)
  (test-begin
    (reset-state!)
    body ...))

(test-with-default
  (check-equal? #f (cpus))
  (check-exn exn:fail? (lambda () (cpus 'not-a-number)))
  (cpus 10)
  (check-equal? 10 (cpus))
  (check-exn exn:fail? (lambda() (cpus 12))))

(test-with-default
  (check-equal? #f (tasks))
  (check-exn exn:fail? (lambda () (tasks 'not-a-number)))
  (tasks 10)
  (check-equal? 10 (tasks))
  (check-exn exn:fail? (lambda () (tasks 12))))

(provide test-with-default)
