#lang rosette/safe

(require "cpu.rkt"
         "../topology.rkt"
         (only-in racket/list range))

(module+ test
  (require rackunit
           rackunit/text-ui))

(provide (struct-out hidden-state)
         total-nr-tasks
         any-cpus-overloaded?
         any-cpus-idle?
         get-cpu-by-id
         construct-hidden-state-var)

(struct hidden-state
  (cpus
   nr-cpus)
  #:transparent)

;; Generate a symbolic variable representing a hidden-state
(define (hidden-state?? nr-cpus)
  (define cpus (map hidden-cpu?? (range nr-cpus)))
  (hidden-state cpus nr-cpus))

;; get total task count
(define (total-nr-tasks state)
  (foldl (lambda (cpu acc) (+ acc (hidden-cpu-nr-tasks cpu))) 0 (hidden-state-cpus state)))

;; Checks if any CPU is overloaded
(define (any-cpus-overloaded? state)
  (define cpus (hidden-state-cpus state))
  (ormap hidden-cpu-overloaded? cpus))

;; Checks if any CPU is idle
(define (any-cpus-idle? state)
  (define cpus (hidden-state-cpus state))
  (ormap hidden-cpu-idle? cpus))

;; Retrieves a hidden-cpu by the id
;; If there is no match, returns #f
(define (get-cpu-by-id state id)
  (define cpus (hidden-state-cpus state))
  (define (rec cpu-list)
    (cond
      [(null? cpu-list) #f]
      [(equal? (hidden-cpu-cpu-id (car cpu-list)) id)
       (car cpu-list)]
       [else (rec (cdr cpu-list))]))
  (rec cpus))

(module+ test
  (run-tests
   (test-suite
    "get-cpu-by-id"
    (test-case
      "check retrieving a value in the list"
      (let* [(cpu0 (hidden-cpu 0 0))
             (cpu1 (hidden-cpu 1 1))
             (hidden (hidden-state (list cpu0 cpu1) 2))]
        (check-equal? cpu0 (get-cpu-by-id hidden 0))))
    (test-case
      "check if ID of a symbolic hidden-cpu is correct"
      (let* [(hidden (hidden-state?? 2))
             (found-cpu (get-cpu-by-id hidden 0))]
         (check-pred hidden-cpu? found-cpu)
         (check-equal? 0 (hidden-cpu-cpu-id found-cpu)))))))

;; Given a topology, constructs a symbolic variable representing
;; its hidden state
(define (construct-hidden-state-var topology)
  (define nr-cpus (topology-size topology))
  (hidden-state?? nr-cpus))
