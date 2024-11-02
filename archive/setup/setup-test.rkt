#lang racket

(require rackunit
         "main.rkt")

;; runs a test starting from the default state
(define-syntax-rule (test-with-default body ...)
  (test-begin
   (reset-state!)
   body ...))

(test-with-default
 (check-false
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

(provide test-with-default)
