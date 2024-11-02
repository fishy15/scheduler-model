#lang racket/base

(require rackunit
         json
         "hidden.rkt")

(define single-datapoint
  (with-input-from-file "single.json"
    (lambda ()
      (list-ref (read-json) 0))))

(displayln (read-from-json single-datapoint))

