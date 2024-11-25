#lang racket/base

(require "state.rkt")

(module+ test
  (require rackunit
           json))

(provide read-from-json)

(define (read-sd sd)
  sd)

(define (read-rq rq)
  rq)

(define (read-mask mask)
  (hash-ref mask 'mask))

(define (read-lb-env env)
  (define (access key)
    (hash-ref env key))
  (lb-env
    (read-sd (access 'sd))
    (read-rq (access 'src_rq))
    (access 'src_cpu)
    (access 'dst_cpu)
    (read-rq (access 'dst_rq))
    (read-mask (access 'dst_grpmask))
    (access 'new_dst_cpu)
    (access 'idle)
    (access 'imbalance)
    (read-mask (access 'cpus))
    (access 'flags)
    (access 'loop)
    (access 'loop_break)
    (access 'loop_max)
    (access 'fbq_type)
    (access 'migration_type)))

(define (read-lb-logmsg logmsg)
  (if (hash-ref logmsg 'runs_load_balance)
      (let ([lb-env (hash-ref logmsg 'lb_env)])
        (read-lb-env lb-env))
      #f))

(define (read-sd-entry entry)
  (define (access key)
    (hash-ref entry key))
  (sd-entry
    (access 'max_newidle_lb_cost)
    (access 'continue_balancing)
    (access 'interval)
    (access 'need_serialize)
    (read-lb-logmsg (access 'lb_logmsg))
    (access 'new_idle)
    (access 'new_busy)))

(define (read-from-json obj)
  (visible-state
    (hash-ref obj 'cpu)
    (hash-ref obj 'idle)
    (hash-ref obj 'sched_idle_cpu)
    (for/list ([sd-entry (hash-ref obj 'sd_buf)])
      (read-sd-entry sd-entry))))

(module+ test
  (define single-datapoint
    (with-input-from-file "single.json"
      (lambda ()
        (list-ref (read-json) 0))))
  (displayln (read-from-json single-datapoint)))

