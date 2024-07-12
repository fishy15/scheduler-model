#lang racket

(require "cpus.rkt"
         "tasks.rkt")

(define (reset-state!)
  (reset-cpu-state!)
  (reset-task-state!))

(provide cpus
         (struct-out task)
         create-task!
         reset-state!)
