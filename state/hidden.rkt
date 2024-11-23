#lang rosette/safe

(require (only-in racket/list range)
         "topology.rkt")

(provide (struct-out hidden-cpu)
         (struct-out hidden-state)
         construct-hidden-state-var
         hidden-cpu-overloaded?
         hidden-cpu-idle?
         any-cpus-overloaded?
         any-cpus-idle?
         get-cpu-by-id
         hidden-state??
         hidden-cpu??
         total-nr-tasks)

(struct hidden-cpu
  (cpu-id
   nr-tasks)
  #:transparent)

;; Generate a symbolic variable representing a hidden-cpu
(define (hidden-cpu?? cpu-id)
  (define-symbolic* nr-tasks integer?)
  (hidden-cpu cpu-id nr-tasks))

(define (hidden-cpu-overloaded? cpu)
  (> (hidden-cpu-nr-tasks cpu) 1))

(define (hidden-cpu-idle? cpu)
  (= (hidden-cpu-nr-tasks cpu) 0))

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

;; Given a topology, constructs a symbolic variable representing
;; its hidden state
(define (construct-hidden-state-var topology)
  (define nr-cpus (topology-size topology))
  (hidden-state?? nr-cpus))
