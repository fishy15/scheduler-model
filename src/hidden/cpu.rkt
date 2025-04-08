#lang rosette/safe

(module+ test
  (require rackunit
           rackunit/text-ui))

(provide (struct-out hidden-cpu)
         hidden-cpu??
         hidden-cpu-overloaded?
         hidden-cpu-idle?
         cpu-list-symbolic-vars)

(struct hidden-cpu
  (cpu-id
   nr-tasks
   cpu-load)
  #:transparent)

;; Generate a symbolic variable representing a hidden-cpu
(define (hidden-cpu?? cpu-id)
  (define-symbolic* nr-tasks integer?)
  (define-symbolic* cpu-load integer?)
  (hidden-cpu cpu-id nr-tasks cpu-load))

(define (hidden-cpu-overloaded? cpu)
  (> (hidden-cpu-nr-tasks cpu) 1))

(define (hidden-cpu-idle? cpu)
  (= (hidden-cpu-nr-tasks cpu) 0))

;; List symbolic variables in a hidden cpu
(define (cpu-list-symbolic-vars cpu)
  (list (hidden-cpu-nr-tasks cpu)
        (hidden-cpu-cpu-load cpu)))

(module+ test
  (run-tests
   (test-suite
    "CPU overloaded/idle"
    (let ()
      (begin
        (define (test-with-id id)
          (define cpu0 (hidden-cpu id 0 0))
          (define cpu1 (hidden-cpu id 1 1))
          (define cpu2 (hidden-cpu id 2 2))

          (test-false "overloaded on 0 tasks" (hidden-cpu-overloaded? cpu0))
          (test-false "overloaded on 1 task"  (hidden-cpu-overloaded? cpu1))
          (test-true  "overloaded on 2 tasks" (hidden-cpu-overloaded? cpu2))

          (test-true  "idle on 0 tasks" (hidden-cpu-idle? cpu0))
          (test-false "idle on 1 task"  (hidden-cpu-idle? cpu1))
          (test-false "idle on 2 tasks" (hidden-cpu-idle? cpu2)))

        (map test-with-id '(0 1 2 3)))))))
