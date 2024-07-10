#lang racket

(require racket/struct
         "arch.rkt")

(define (check-container-of-type container? container-name type? type-name)
  (lambda (container arg-desc name)
    (unless (container? container)
      (raise-argument-error name
                            (format "~a must be a ~a" arg-desc container-name)
                            container))
    (for ([elem container])
      (unless (type? elem)
        (raise-argument-error name
                              (format "~a must consist of ~as" arg-desc type-name)
                              container)))))

(define check-set-of-arch-cpus
  (check-container-of-type set? "set" arch-cpu? "arch-cpu"))

(define (union-group-cpu-sets groups)
  (apply set-union (map sched-group-cpus groups)))

(struct sched-group (cpus)
  #:guard (lambda (cpus name)
            (check-set-of-arch-cpus cpus "first argument" name)
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

(define check-list-of-sched-groups
  (check-container-of-type list? "list" sched-group? "sched-group"))

(struct sched-domain (cpu-set groups children)
  #:guard (lambda (cpu-set groups children name)
            (check-set-of-arch-cpus cpu-set "first argument" name)
            (check-list-of-sched-groups groups "second argument" name)
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
  (define cpu-set (union-group-cpu-sets groups))
  (sched-domain cpu-set groups children))

(provide
 (struct-out sched-group)
 (struct-out sched-domain)
 make-sched-domain)