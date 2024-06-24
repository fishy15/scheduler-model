#lang racket

(define (group-overloaded nr-cpus nr-running group-util group-runnable)
  ;; not always true since there exist some RT tasks that cannot be disabled
  ;; however we will assume that they have neglible impact
  (define group-capacity (* 1024 nr-cpus))
  ;; reciprocal of 0.85
  (define imbalance-pct 117)
  (cond
    [(<= nr-running nr-cpus) #f]
    [(< (group-capacity * 100) (* group-util imbalance-pct)) #t]
    [(< (group-capacity * imbalance-pct) (* group-runnable 100)) #t]
    [else #f]))
