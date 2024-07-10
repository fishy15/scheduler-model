#lang racket

(require rackunit
         "utils.rkt")

(define-syntax-rule (pair-test lst expected)
  (test-begin
   (define pairs
     (sequence->list (unordered-pairs lst)))
   (check-equal? pairs
                 expected
                 (format "check pairs of ~a" lst))))

(pair-test '()
           '())

(pair-test '(1)
           '())

(pair-test '(1 2)
           '((1 . 2)))

(pair-test '(1 2 3)
           '((1 . 2) (1 . 3) (2 . 3)))