#lang rosette/safe

(require rackunit
         json
         "visible.rkt")

(define single-datapoint
  (with-input-from-file "single.json"
    (lambda ()
      (list-ref (read-json) 0))))

(displayln (read-from-json single-datapoint))

