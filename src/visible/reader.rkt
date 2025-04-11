#lang racket/base

(require "state.rkt")

(module+ test
  (require rackunit
           json))

(provide read-from-json)

(define (read-from-json obj)
  (visible-state
   (read-all-sd-info (hash-ref obj 'per-sd-info))
   (read-all-cpu-info (hash-ref obj 'per-cpu-info))))

(define (read-all-sd-info obj)
  (map read-sd-info obj))

(define (read-sd-info obj)
  (visible-sd-info
   (read-sd (hash-ref obj 'sd))
   (read-all-sg-info (hash-ref obj 'groups))))

(define (read-sd obj)
  (visible-sd
   (hash-ref obj 'dst-cpu)
   (hash-ref obj 'cpumask)
   (hash-ref obj 'fbq-type)
   (hash-ref obj 'migration-type)
   (hash-ref obj 'group-balance-cpu-sg)
   (hash-ref obj 'asym-cpucapacity)
   (hash-ref obj 'asym-packing)
   (hash-ref obj 'share-cpucapacity)
   (hash-ref obj 'should-we-balance)
   (hash-ref obj 'has-busiest)
   (hash-ref obj 'avg-load)
   (hash-ref obj 'imbalance-pct)
   (hash-ref obj 'smt-active)
   (hash-ref obj 'imbalance)
   (hash-ref obj 'span-weight)
   (hash-ref obj 'src-cpu)))

(define (read-all-sg-info obj)
  (map read-sg-info obj))

(define (read-sg-info obj)
  (visible-sg-info
   (hash-ref obj 'cpumask)
   (hash-ref obj 'group-type)
   (hash-ref obj 'sum-h-nr-running)
   (hash-ref obj 'sum-nr-running)
   (hash-ref obj 'max-capacity)
   (hash-ref obj 'min-capacity)
   (hash-ref obj 'avg-load)
   (hash-ref obj 'asym-prefer-cpu)
   (hash-ref obj 'misfit-task-load)
   (hash-ref obj 'idle-cpus)
   (hash-ref obj 'group-balance-cpu)))

(define (read-all-cpu-info obj)
  (map read-cpu-info obj))

(define (read-cpu-info obj)
  (visible-cpu-info
   (hash-ref obj 'fbq-type)
   (hash-ref obj 'cpu-idle-type)
   (hash-ref obj 'idle-cpu)
   (hash-ref obj 'is-core-idle)
   (hash-ref obj 'nr-running)
   (hash-ref obj 'h-nr-running)
   (hash-ref obj 'ttwu-pending)
   (hash-ref obj 'capacity)
   (hash-ref obj 'asym-cpu-priority)
   (hash-ref obj 'rd-overutilized)
   (hash-ref obj 'rd-pd-overlap)
   (hash-ref obj 'arch-scale-cpu-capacity)
   (hash-ref obj 'cpu-load)
   (hash-ref obj 'cpu-util-cfs-boost)
   (hash-ref obj 'misfit-task-load)
   (hash-ref obj 'llc-weight)
   (hash-ref obj 'has-sd-share)
   (hash-ref obj 'nr-idle-scan)))

(module+ test
  (define single-datapoint
    (with-input-from-file "single.json"
      (lambda ()
        (list-ref (read-json) 0))))
  (displayln (read-from-json single-datapoint)))
