#lang rosette/safe

(require "cpu.rkt"
         "state.rkt")

(provide (struct-out hidden-cpu)
         (struct-out hidden-state)
         construct-hidden-state-var
         hidden-cpu-overloaded?
         hidden-cpu-idle?
         hidden-any-cpus-overloaded?
         hidden-any-cpus-idle?
         hidden-get-cpu-by-id
         hidden-max-load
         list-symbolic-vars
         hidden-get-cpus-by-mask
         hidden-group-total-nr-tasks
         hidden-group-total-load
         hidden-total-nr-tasks)

