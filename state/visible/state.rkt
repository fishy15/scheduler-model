#lang racket/base

(provide (struct-out visible-state)
         (struct-out sd-entry)
         (struct-out lb-env))

(struct visible-state
  (cpu
   idle
   sched-idle-cpu
   sd-buf)
  #:transparent)

(struct sd-entry
  (max-newidle-lb-cost
   continue-balancing
   interval
   need-serialize
   lb-logmsg
   new-idle
   new-busy)
  #:transparent)

(struct lb-env
  (sd
   src-rq
   src-cpu
   dst-cpu
   dst-rq
   dst-grpmask
   new-dst-cpu
   idle
   imbalance
   cpus
   flags
   loop
   loop-break
   loop-max
   fbq-type
   migration-type)
  #:transparent)
