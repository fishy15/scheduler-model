#lang racket

(require
  rackunit
  "arch.rkt"
  "sched-structure.rkt"
  "setup.rkt"
  (only-in "setup-test.rkt" test-with-default))

(test-with-default
 (cpus 4)

 (check-not-exn
  (lambda ()
    (sched-group (set (arch-cpu 0) (arch-cpu 1))))
  "constructing sched group from set should pass")

 (check-exn exn:fail:contract?
            (lambda ()
              (sched-group (list (arch-cpu 0) (arch-cpu 0)))
              "constructing sched group from list should fail"))

 (check-exn exn:fail:contract?
            (lambda ()
              (sched-group (set (arch-cpu 0) 1))
              "constructing sched group from set where not all arch-cpus should fail")))

(test-with-default
 (cpus 4)
 (define group1 (sched-group (set (arch-cpu 0) (arch-cpu 1))))
 (define group2 (sched-group (set (arch-cpu 2) (arch-cpu 3))))
 (define group-list (list group1 group2))
 (define domain
   (make-sched-domain group-list))
 (define cpu-set (set (arch-cpu 0) (arch-cpu 1) (arch-cpu 2) (arch-cpu 3)))

 (check-equal?
  domain
  (sched-domain cpu-set group-list '())
  "sched domain should have correct cpu set and groups")

 (check-exn exn:fail:contract?
            (lambda ()
              (make-sched-domain (set group1 group2))))

 (check-exn exn:fail:contract?
            (lambda ()
              (make-sched-domain (list group1 1)))))