#lang racket

(require "./cpus.rkt"
         "./tasks.rkt")

(define (reset-state!)
  (reset-cpu-state!)
  (reset-task-state!))

(provide capacity-per-cpu
         cpus
         (struct-out task)
         task-list
         create-task!
         reset-state!)
