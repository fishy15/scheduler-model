#lang racket

(require "./structs.rkt"
         "./methods.rkt")

(provide (struct-out arch-cpu)
         (struct-out arch-group)
         construct-arch
         get-cpu-set
         cpu-nr-running)
