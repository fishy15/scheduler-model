#lang racket

(require "./structs.rkt"
         "./methods.rkt"
         "./group-type.rkt")

(provide (struct-out arch-cpu)
         (struct-out arch-group)
         construct-arch
         get-cpu-set
         cpu-nr-running
         (all-from-out "./group-type.rkt"))
