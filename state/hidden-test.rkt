#lang rosette/safe

(require rackunit
         "hidden.rkt")

(test-begin
  (define cpu0 (hidden-cpu 0 0))
  (define cpu1 (hidden-cpu 1 1))
  (define hidden (hidden-state (list cpu0 cpu1)))
  (check-equal? cpu0 (get-cpu-by-id hidden 0)))

(test-begin
  (define hidden (hidden-state?? 2))
  (define found-cpu (get-cpu-by-id hidden 0))
  (check-pred hidden-cpu? found-cpu)
  (check-equal? 0 (hidden-cpu-cpu-id found-cpu)))
