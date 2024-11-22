#lang rosette/safe

(require "hidden.rkt"
         "visible.rkt")

;; Checks if the given hidden state could produce the given visible state
(define (valid hidden visible)
  #t)

;; Checks if the load balancer made the correct decision
(define (correct hidden visible)
  (overloaded-to-idle hidden visible))

(define (san2 hidden visible)
  (define cpu0 (get-cpu-by-id hidden 0))
  (equal? (hidden-cpu-nr-tasks cpu0) 0))

(define (sanity hidden visible)
  #f)

;; Checks if there exists an overloaded CPU (>= 2 tasks) and an idle CPU (= 0 tasks),
;; then the scheduler attempts to make progress by moving some tasks
;; from an overloaded CPU to an idle CPU.
(define (overloaded-to-idle hidden visible)
  (define any-overloaded (any-cpus-overloaded? hidden))
  (define any-idle (any-cpus-idle? hidden))
  (if (and any-overloaded any-idle)
      (begin
        ;; Checks if it moves overloaded -> idle in this sd-buf iteration
        (define (check-sd-buf sd-buf)
          (define env (sd-entry-lb-logmsg sd-buf))
          (if env
              (begin
                (define src-cpu (lb-env-src-cpu env))
                (define dst-cpu (lb-env-dst-cpu env))
                (and (hidden-cpu-overloaded? (get-cpu-by-id hidden src-cpu))
                     (hidden-cpu-idle? (get-cpu-by-id hidden dst-cpu))))
              #f))
        (ormap check-sd-buf (visible-state-sd-buf visible)))
      #t))

(provide valid
         correct)
