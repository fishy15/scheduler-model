#lang rosette/safe

(require "cpu.rkt"
         "../topology.rkt"
         (only-in racket/base
                  for/list
                  in-string
                  list->string
                  string->list)
         (only-in racket/list range))

(module+ test
  (require rackunit
           rackunit/text-ui))

(provide (struct-out hidden-state)
         hidden-total-nr-tasks
         hidden-any-cpus-overloaded?
         hidden-any-cpus-idle?
         hidden-get-cpu-by-id
         list-symbolic-vars
         hidden-get-cpus-by-mask
         hidden-group-total-nr-tasks
         hidden-group-total-load
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
(define (hidden-total-nr-tasks state)
  (foldl (lambda (cpu acc) (+ acc (hidden-cpu-nr-tasks cpu))) 0 (hidden-state-cpus state)))

;; Checks if any CPU is overloaded
(define (hidden-any-cpus-overloaded? state)
  (define cpus (hidden-state-cpus state))
  (ormap hidden-cpu-overloaded? cpus))

;; Checks if any CPU is idle
(define (hidden-any-cpus-idle? state)
  (define cpus (hidden-state-cpus state))
  (ormap hidden-cpu-idle? cpus))

;; Retrieves a hidden-cpu by the id
;; If there is no match, returns #f
(define (hidden-get-cpu-by-id state id)
  (define cpus (hidden-state-cpus state))
  (define (rec cpu-list)
    (cond
      [(null? cpu-list) #f]
      [(equal? (hidden-cpu-cpu-id (car cpu-list)) id)
       (car cpu-list)]
      [else (rec (cdr cpu-list))]))
  (rec cpus))

(define (list-symbolic-vars hidden)
  (apply append (map cpu-list-symbolic-vars (hidden-state-cpus hidden))))

(module+ test
  (run-tests
   (test-suite
    "get-cpu-by-id"
    (test-case
     "check retrieving a value in the list"
     (let* [(cpu0 (hidden-cpu 0 0 0))
            (cpu1 (hidden-cpu 1 1 0))
            (hidden (hidden-state (list cpu0 cpu1) 2))]
       (check-equal? cpu0 (hidden-get-cpu-by-id hidden 0))))
    (test-case
     "check if ID of a symbolic hidden-cpu is correct"
     (let* [(hidden (hidden-state?? 2))
            (found-cpu (hidden-get-cpu-by-id hidden 0))]
       (check-pred hidden-cpu? found-cpu)
       (check-equal? 0 (hidden-cpu-cpu-id found-cpu)))))))

;; Given a cpu mask (in little endian order),
;; return the list of cpus that are marked
(define (hidden-get-cpus-by-mask state mask)
  (define big-endian-mask (list->string (reverse (string->list mask))))
  (for/list ([present (in-string big-endian-mask)]
             [cpu (hidden-state-cpus state)]
             #:when (eq? present #\1))
    cpu))

;; Sums the number of tasks running in the mask
(define (hidden-group-total-nr-tasks state mask)
  (apply + (map hidden-cpu-nr-tasks (hidden-get-cpus-by-mask state mask))))

;; Sums the loads on each state in the mask
(define (hidden-group-total-load state mask)
  (apply + (map hidden-cpu-cpu-load (hidden-get-cpus-by-mask state mask))))

(module+ test
  (run-tests
   (test-suite
    "get-cpu-mask"
    (test-case
     "check if returning a full mask is correct"
     (let* [(cpu0 (hidden-cpu 0 0 0))
            (cpu1 (hidden-cpu 1 1 0))
            (hidden (hidden-state (list cpu0 cpu1) 2))]
       (check-equal? (list cpu0 cpu1) (hidden-get-cpus-by-mask hidden "11"))))
    (test-case
     "check if returning a mask with first value is correct"
     (let* [(cpu0 (hidden-cpu 0 0 0))
            (cpu1 (hidden-cpu 1 1 0))
            (hidden (hidden-state (list cpu0 cpu1) 2))]
       (check-equal? (list cpu0) (hidden-get-cpus-by-mask hidden "01"))))
    (test-case
     "check if returning a mask with second value is correct"
     (let* [(cpu0 (hidden-cpu 0 0 0))
            (cpu1 (hidden-cpu 1 1 0))
            (hidden (hidden-state (list cpu0 cpu1) 2))]
       (check-equal? (list cpu1) (hidden-get-cpus-by-mask hidden "10"))))
    (test-case
     "check if returning a mask with no values is correct"
     (let* [(cpu0 (hidden-cpu 0 0 0))
            (cpu1 (hidden-cpu 1 1 0))
            (hidden (hidden-state (list cpu0 cpu1) 2))]
       (check-equal? '() (hidden-get-cpus-by-mask hidden "00")))))))

;; Given a topology, constructs a symbolic variable representing
;; its hidden state
(define (construct-hidden-state-var topology)
  (define nr-cpus (topology-size topology))
  (hidden-state?? nr-cpus))
