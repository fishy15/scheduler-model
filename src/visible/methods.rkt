#lang racket/base

(require "state.rkt")

(module+ test
  (require json
           rackunit
           rackunit/text-ui
           "reader.rkt"))

(provide visible-state-nr-cpus
         visible-state-get-cpu)

(module+ test
  (define single-datapoint-json
    (with-input-from-file "single.json"
      (lambda ()
        (list-ref (read-json) 0))))
  (define single-datapoint (read-from-json single-datapoint-json)))

(define (visible-state-nr-cpus visible)
  (length (visible-state-per-cpu-info visible)))

(module+ test
  (run-tests
   (test-suite
    "nr-cpus"
    (let ()
      (begin
        (test-eq? "nr-cpus on single-data" (visible-state-nr-cpus single-datapoint) 2))))))

(define (visible-state-get-cpu visible cpu-id)
  (define per-cpu-info (visible-state-per-cpu-info visible))
  (list-ref per-cpu-info cpu-id))