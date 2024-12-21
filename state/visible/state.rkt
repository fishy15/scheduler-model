#lang racket/base

(provide (struct-out visible-state)
         (struct-out sd-entry)
         (struct-out lb-logmsg)
         (struct-out lb-env)
         (struct-out swb-logmsg)
         (struct-out fbg-logmsg)
         (struct-out fbq-logmsg)
         (struct-out swb-per-cpu-logmsg)
         (struct-out fbg-stat)
         (struct-out fbq-per-cpu-logmsg))

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

(struct lb-logmsg
  (lb-env
   swb-logmsg
   fbg-logmsg
   fbq-logmsg)
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

(struct swb-logmsg
  (swb-cpus
   dst-cpu
   cpus
   idle
   dst-nr-running
   dst-ttwu-pending
   per-cpu-msgs
   group-balance-mask-sg
   group-balance-cpu-sg)
  #:transparent)

(struct swb-per-cpu-logmsg
  (cpu-id
   idle-cpu
   is-core-idle-cpu)
  #:transparent)

(struct fbg-logmsg
  (sd-total-load
   sd-total-capacity
   sd-avg-load
   sd-prefer-sibling
   busiest-stat
   local-stat
   sched-energy-enabled
   rd-perf-domain-exists
   rd-overutilized
   env-imbalanced)
  #:transparent)

(struct fbg-stat
  (avg-load
   group-load
   group-capacity
   group-util
   group-runnable
   sum-nr-running
   sun-h-nr-running
   idle-cpus
   group-weight
   group-type
   group-asym-packing
   group-smt-balance
   group-misfit-task-load)
  #:transparent)

(struct fbq-logmsg
  (capacity-dst-cpu
   sched-smt-active
   arch-asym-cpu-priority-dst-cpu
   per-cpu-msgs)
  #:transparent)

(struct fbq-per-cpu-logmsg
  (cpu-id
   rq-type
   rq-cfs-h-nr-running
   capacity
   arch-asym-cpu-priority
   migration-type
   cpu-load
   rq-cpu-capacity
   arch-scale-cpu-capacity
   sd-imbalance-pct
   cpu-util-cfs-boost
   rq-misfit-task-load)
  #:transparent)
