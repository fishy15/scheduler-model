#lang racket

(require "../arch/structs.rkt")

(define task-list '())

;; not always true since there exist some RT tasks that cannot be disabled
;; these tasks consume some capacity, so the total capacity is
;; however we will assume that they have neglible impact
(define capacity-per-cpu 1024)

;; saw in observation that the maximum is 2771, but no clue about accuracy
(define max-runnable-time 2771)

(struct task (cpu running util runnable) #:transparent
  #:guard
  (lambda (cpu running util runnable name)
    (unless (arch-cpu? cpu)
      (raise-argument-error name
                            "first argument should be an arch-cpu"
                            cpu))
    (unless (boolean? running)
      (raise-argument-error name
                            "second argument should be boolean"
                            running))
    (unless (and (nonnegative-integer? util)
                 (<= util capacity-per-cpu))
      (raise-argument-error name
                            "third argument should be between 0 and 1024"
                            util))
    (unless (and (nonnegative-integer? runnable)
                 (<= util max-runnable-time))
      (raise-argument-error name
                            "fourth argument should be between 0 and 1024"
                            runnable))
    (values cpu running util runnable)))

;; Creates a task that start out on the given CPU
;; and in the given running state. If no running state is given,
;; it is assumed to be true.
(define (create-task! #:cpu cpu
                      #:running [running #t]
                      #:util util
                      #:runnable runnable)
  (define conv-cpu
    (cond
      [(integer? cpu) (arch-cpu cpu)]
      [(arch-cpu? cpu) cpu]
      [else
       (raise-argument-error 'create-task!
                             "cpu should be an integer or an arch-cpu"
                             cpu)]))
  (set! task-list
        (append task-list (list (task conv-cpu running util runnable))))
  (void))

(define (reset-task-state!)
  (set! task-list '()))

(provide capacity-per-cpu
         (struct-out task)
         create-task!
         task-list
         reset-task-state!)