#lang racket/base

(require "../util/kw-struct.rkt")

(provide (struct-out visible-state)
         visible-state->json-string
         (struct-out visible-sd-info)
         visible-sd-info->json-string
         (struct-out visible-sd)
         visible-sd->json-string
         (struct-out visible-sg-info)
         visible-sg-info->json-string
         (struct-out visible-cpu-info)
         visible-cpu-info->json-string)

(define-struct-with-writer visible-state
  (per-sd-info
   per-cpu-info))

(define-struct-with-writer visible-sd-info
  (sd
   groups))

(define-struct-with-writer visible-sd
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

(define-struct-with-writer visible-sg-info
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

(define-struct-with-writer visible-cpu-info
  (cpu-id
   fbq-type
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