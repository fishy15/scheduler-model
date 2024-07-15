#lang racket

(require "../arch/structs.rkt")

(define task-list '())

(struct task (cpu running) #:transparent
  #:guard
  (lambda (cpu running name)
    (unless (arch-cpu? cpu)
      (raise-argument-error name
                            "first argument should be an arch-cpu"
                            cpu))
    (unless (boolean? running)
      (raise-argument-error name
                            "second argument should be boolean"
                            running))
    (values cpu running)))

;; Creates a task that start out on the given CPU
;; and in the given running state. If no running state is given,
;; it is assumed to be true.
(define (create-task! #:cpu cpu
                      #:running [running #t])
  (define conv-cpu
    (cond
      [(integer? cpu) (arch-cpu cpu)]
      [(arch-cpu? cpu) cpu]
      [else
       (raise-argument-error 'create-task!
                             "cpu should be an integer or an arch-cpu"
                             cpu)]))
  (set! task-list
        (append task-list (list (task conv-cpu running))))
  (void))

(define (reset-task-state!)
  (set! task-list '()))

(provide (struct-out task)
         create-task!
         task-list
         reset-task-state!)