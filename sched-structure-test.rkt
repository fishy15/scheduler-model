#lang racket

(require
  rackunit
  "arch.rkt"
  "sched-structure.rkt"
  "setup/main.rkt"
  (only-in "setup/setup-test.rkt" test-with-default))

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
 (define domain
   (make-sched-domain group1 group2))
 (define cpu-set (set (arch-cpu 0) (arch-cpu 1) (arch-cpu 2) (arch-cpu 3)))

 (check-equal?
  domain
  (sched-domain cpu-set (list group1 group2) #f)
  "sched domain should have correct cpu set and groups")

 (check-exn exn:fail:contract?
            (lambda ()
              (make-sched-domain group1 1)))

 (check-exn exn:fail:contract?
            (lambda ()
              (make-sched-domain group1 group1))))

(test-with-default
 (cpus 4)

 (define arch
   (construct-arch '((0 1) (2 3))))

 (define global-domain
   (make-sched-domain
    (make-sched-group 0 1)
    (make-sched-group 2 3)))

 (define subdomain1
   (make-sched-domain
    (make-sched-group 0)
    (make-sched-group 1)
    #:parent global-domain))

 (define subdomain2
   (make-sched-domain
    (make-sched-group 2)
    (make-sched-group 3)
    #:parent global-domain))

 (define intended-domains
   (rotate-all-groups-until-cpu-first
    (make-immutable-hash
     (list (cons (arch-cpu 0) subdomain1)
           (cons (arch-cpu 1) subdomain1)
           (cons (arch-cpu 2) subdomain2)
           (cons (arch-cpu 3) subdomain2)))))

 (check-equal?
  intended-domains
  (domain-from-arch arch)))

(test-with-default
 (cpus 4)

 (define global-domain-for-01
   (make-sched-domain
    (make-sched-group 0 1)
    (make-sched-group 2 3)))

 (define global-domain-for-23
   (make-sched-domain
    (make-sched-group 2 3)
    (make-sched-group 0 1)))

 (define subdomain1-for-0
   (make-sched-domain
    (make-sched-group 0)
    (make-sched-group 1)
    #:parent global-domain-for-01))

 (define subdomain1-for-1
   (make-sched-domain
    (make-sched-group 1)
    (make-sched-group 0)
    #:parent global-domain-for-01))

 (define subdomain2-for-2
   (make-sched-domain
    (make-sched-group 2)
    (make-sched-group 3)
    #:parent global-domain-for-23))

 (define subdomain2-for-3
   (make-sched-domain
    (make-sched-group 3)
    (make-sched-group 2)
    #:parent global-domain-for-23))

 ;; wrong means both segments need to be flipped
 (define wrong-for-0
   (make-sched-domain
    (make-sched-group 1)
    (make-sched-group 0)
    #:parent global-domain-for-23))

 (define wrong-for-1
   (make-sched-domain
    (make-sched-group 0)
    (make-sched-group 1)
    #:parent global-domain-for-23))

 (define wrong-for-2
   (make-sched-domain
    (make-sched-group 3)
    (make-sched-group 2)
    #:parent global-domain-for-01))

 (define wrong-for-3
   (make-sched-domain
    (make-sched-group 2)
    (make-sched-group 3)
    #:parent global-domain-for-01))

 (for [(subdomain (list subdomain1-for-0 subdomain1-for-1 wrong-for-0 wrong-for-1))]
   (check-equal?
    (rotate-groups-until-cpu-first subdomain (arch-cpu 0))
    subdomain1-for-0)
   (check-equal?
    (rotate-groups-until-cpu-first subdomain (arch-cpu 1))
    subdomain1-for-1))

 (for [(subdomain (list subdomain2-for-2 subdomain2-for-3 wrong-for-2 wrong-for-3))]
   (check-equal?
    (rotate-groups-until-cpu-first subdomain (arch-cpu 2))
    subdomain2-for-2)
   (check-equal?
    (rotate-groups-until-cpu-first subdomain (arch-cpu 3))
    subdomain2-for-3))

 (define inital-domains
   (make-immutable-hash
    (list (cons (arch-cpu 0) wrong-for-0)
          (cons (arch-cpu 1) wrong-for-1)
          (cons (arch-cpu 2) wrong-for-2)
          (cons (arch-cpu 3) wrong-for-3))))

 (define wanted-domains
   (make-immutable-hash
    (list (cons (arch-cpu 0) subdomain1-for-0)
          (cons (arch-cpu 1) subdomain1-for-1)
          (cons (arch-cpu 2) subdomain2-for-2)
          (cons (arch-cpu 3) subdomain2-for-3))))

 (check-equal?
  wanted-domains
  (rotate-all-groups-until-cpu-first inital-domains)))