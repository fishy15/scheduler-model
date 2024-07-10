#lang racket

(require racket/struct
         "arch.rkt"
         (only-in "utils.rkt"
                  check-container-of-type
                  unordered-pairs))

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

;; TODO: implement "The group pointed to by the ->groups pointer MUST contain 
;;       "the CPU to which the domain belongs."
(struct sched-domain (cpu-set groups children)
  #:guard (lambda (cpu-set groups children name)
            (check-set-of-arch-cpus cpu-set "first argument" name)
            (check-list-of-sched-groups groups "second argument" name)
            
            ;; checking that no two groups intersect
            ;; currently SD_OVERLAP is not supported
            (for ([group-pair (unordered-pairs groups)])
              (match group-pair
                [(cons a b)
                 (define common
                   (set-intersect
                    (sched-group-cpus a)
                    (sched-group-cpus b)))
                 (unless (set-empty? common)
                   (raise-argument-error name
                                         "sched groups should have disjoint cpu sets"
                                         groups))]))
            (values cpu-set groups children))
  #:methods gen:equal+hash
  [(define (equal-proc a b equal?-recur)
     (and (equal?-recur (sched-domain-cpu-set a) (sched-domain-cpu-set b))
          (equal?-recur (sched-domain-groups a) (sched-domain-groups b))
          (equal?-recur (sched-domain-children a) (sched-domain-children b))))
   (define (hash-proc a hash-recur)
     (+ (hash-recur (sched-domain-cpu-set a))
        (hash-recur (sched-domain-groups a))
        (hash-recur (sched-domain-children a))))
   (define (hash2-proc a hash2-recur)
     (+ (hash2-recur (sched-domain-cpu-set a))
        (* 3 (hash2-recur (sched-domain-groups a)))
        (* 5 (hash2-recur (sched-domain-children a)))))]
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (lambda (obj) 'sched-domain)
      (lambda (obj) (list (sched-domain-groups obj) (sched-domain-children obj)))))])

(define (make-sched-domain groups [children '()])
  (define cpu-set (union-group-cpu-sets groups))
  (sched-domain cpu-set groups children))

(provide
 (struct-out sched-group)
 (struct-out sched-domain)
 make-sched-domain)