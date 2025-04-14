#lang racket/base

(require "../util/kw-struct.rkt")

(provide (struct-out visible-state)
         (struct-out visible-sd-info)
         (struct-out visible-sd)
         (struct-out visible-sg-info)
         (struct-out visible-cpu-info))

(define-kw-struct visible-state
  (per-sd-info
   per-cpu-info))

(define-kw-struct visible-sd-info
  (sd
   groups))

(define-kw-struct visible-sd
  (dst-cpu
   cpumask
   fbq-type
   migration-type
   group-balance-cpu-sg
   asym-cpucapacity
   asym-packing
   share-cpucapacity
   should-we-balance
   has-busiest
   avg-load
   imbalance-pct
   smt-active
   imbalance
   span-weight
   src-cpu
   prefer-sibling
   sd-share-llc
   sd-numa
   nr-tasks-moved))

(define-kw-struct visible-sg-info
  (cpumask
   group-type
   sum-h-nr-running
   sum-nr-running
   max-capacity
   min-capacity
   avg-load
   asym-prefer-cpu
   idle-cpus
   group-balance-cpu
   group-weight
   asym-packing
   smt-balance
   misfit-task-load
   group-capacity
   group-util
   group-runnable
   group-imbalance))

(define-kw-struct visible-cpu-info
  (fbq-type
   cpu-idle-type
   idle-cpu
   is-core-idle
   nr-running
   h-nr-running
   ttwu-pending
   capacity
   asym-cpu-priority
   rd-overutilized
   rd-pd-overlap
   arch-scale-cpu-capacity
   cpu-load
   cpu-util-cfs-boost
   misfit-task-load
   llc-weight
   has-sd-share
   nr-idle-scan))