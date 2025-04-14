#lang racket/base

(require "state.rkt")

(module+ test
  (require json
           rackunit
           rackunit/text-ui
           "reader.rkt"))

(provide visible-state-nr-cpus
         visible-state-get-cpu
         visible-did-tasks-move?)

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
        (test-eq? "nr-cpus on single-data" (visible-state-nr-cpus single-datapoint) 16))))))

(define (visible-state-get-cpu visible cpu-id)
  (define per-cpu-info (visible-state-per-cpu-info visible))
  (list-ref per-cpu-info cpu-id))

(define (visible-did-tasks-move? sd-info)
  (let ([sd (visible-sd-info-sd sd-info)])
    (and (not (eq? 'null (visible-sd-src-cpu sd)))
         (> (visible-sd-nr-tasks-moved sd) 0))))