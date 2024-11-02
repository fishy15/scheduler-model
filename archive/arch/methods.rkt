#lang racket

(require "../setup/main.rkt"
         "./structs.rkt")

;; Counts the number of tasks running on a CPU
(define (cpu-nr-running cpu)
  (for/sum ([task task-list])
    (if (equal? cpu (task-cpu task))
        1
        0)))

(provide cpu-nr-running)