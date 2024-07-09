#lang racket

(require racket/struct
         "arch.rkt")

(struct sched-group (cpus)
  #:guard (lambda (cpus name)
            (unless (set? cpus)
              (raise-argument-error name
                                    "set?"
                                    cpus))
            (for ([cpu (in-set cpus)])
              (unless (arch-cpu? cpu)
                (raise-argument-error name
                                      "all cpus must be arch-cpu"
                                      cpus)))
            cpus)
  #:methods gen:equal+hash
  [(define (equal-proc a b equal?-recur)
     (equal?-recur (sched-group-cpus a) (sched-group-cpus b)))
   (define (hash-proc a hash-recur)
     (hash-recur (sched-group-cpus a)))
   (define (hash2-proc a hash2-recur)
     (hash2-recur (sched-group-cpus a)))]
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (lambda (obj) 'sched-group)
      (lambda (obj) (list (sched-group-cpus obj)))))])

(struct sched-domain (cpu-set groups children)
  #:guard (lambda (cpu-set groups children name)
            (unless (set? cpu-set)
              (raise-argument-error name
                                    "set?"
                                    cpu-set))
            (unless (list? groups)
              (raise-argument-error name
                                    "list?"
                                    groups))
            (for ([cpu (in-set cpu-set)])
              (define present
                (for/or ([group groups])
                  (set-member? (sched-group-cpus group) cpu)))
              (unless present
                (raise-arguments-error name
                                       "cpu in cpu set missing from some domain"
                                       "cpu-set" cpu-set
                                       "groups" groups)))
            (values cpu-set groups children))
  #:methods gen:equal+hash
  [(define (equal-proc a b equal?-recur)
     (and (equal?-recur (sched-domain-cpu-set a) (sched-domain-cpu-set b))
          (equal?-recur (sched-domain-groups a) (sched-domain-groups b))))
   (define (hash-proc a hash-recur)
     (+ (hash-recur (sched-domain-cpu-set a))
        (hash-recur (sched-domain-groups a))))
   (define (hash2-proc a hash2-recur)
     (+ (hash2-recur (sched-domain-cpu-set a))
        (* 3 (hash2-recur (sched-domain-groups a)))))]
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (lambda (obj) 'sched-domain)
      (lambda (obj) (list (sched-domain-groups obj)))))])

(define (make-sched-domain groups [children '()])
  (define cpu-set
    (apply set-union (map sched-group-cpus groups)))
  (sched-domain cpu-set groups children))

(provide
 (struct-out sched-group)
 (struct-out sched-domain)
 make-sched-domain)