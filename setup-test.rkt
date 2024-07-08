#lang racket

(require rackunit "setup.rkt")

;; runs a test starting from the default state
(define-syntax-rule (test-with-default body ...)
  (test-begin
    (reset-state!)
    body ...))

(test-with-default
  (check-equal?
    #f
    (cpus)
    "# of cpus should be #f before being set")

  (check-exn exn:fail:contract?
    (lambda () (cpus 0))
    "cannot set # of cpus to 0")

  (check-exn exn:fail:contract?
    (lambda () (cpus 'not-a-number))
    "cannot set # of cpus to a quote")

  (cpus 10)

  (check-equal?
    10
    (cpus)
    "number of cpus should match amount set")

  (check-exn exn:fail:user?
    (lambda() (cpus 12))
    "cannot set # of cpus after it has already been set"))

(test-with-default
  (check-equal?
    #f
    (tasks)
    "# of tasks should be #f before being set")

  (check-exn exn:fail:contract?
    (lambda () (tasks 0))
    "cannot set # of tasks to 0")

  (check-exn exn:fail:contract?
    (lambda () (tasks 'not-a-number)
    "cannot set # of tasks to a quote"))

  (tasks 10)

  (check-equal?
    10
    (tasks)
    "number of tasks should match amount set")
  
  (check-exn exn:fail:user?
    (lambda () (tasks 12))
    "cannot set # of tasks after it has already been set"))

(provide test-with-default)
