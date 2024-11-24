#lang rosette/safe

(require "cpu.rkt"
         "state.rkt")

(provide (struct-out hidden-cpu)
         (struct-out hidden-state)
         construct-hidden-state-var
         hidden-cpu-overloaded?
         hidden-cpu-idle?
         any-cpus-overloaded?
         any-cpus-idle?
         get-cpu-by-id
         total-nr-tasks)

