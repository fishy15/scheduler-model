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

(define (make-sched-group . cpus-numbers)
  (sched-group (list->set (map arch-cpu cpus-numbers))))

(define check-list-of-sched-groups
  (check-container-of-type list? "list" sched-group? "sched-group"))

;; TODO: implement "The group pointed to by the ->groups pointer MUST contain 
;;       "the CPU to which the domain belongs."
(struct sched-domain (cpu-set groups parent)
  #:guard (lambda (cpu-set groups parent name)
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
            
            (unless (or (false? parent) (sched-domain? parent))
              (raise-argument-error name
                                    "third argument should be #f or a sched-domain"
                                    parent))

            (values cpu-set groups parent))
  #:methods gen:equal+hash
  [(define (equal-proc a b equal?-recur)
     (and (equal?-recur (sched-domain-cpu-set a) (sched-domain-cpu-set b))
          (equal?-recur (sched-domain-groups a) (sched-domain-groups b))
          (equal?-recur (sched-domain-parent a) (sched-domain-parent b))))
   (define (hash-proc a hash-recur)
     (+ (hash-recur (sched-domain-cpu-set a))
        (hash-recur (sched-domain-groups a))
        (hash-recur (sched-domain-parent a))))
   (define (hash2-proc a hash2-recur)
     (+ (hash2-recur (sched-domain-cpu-set a))
        (* 3 (hash2-recur (sched-domain-groups a)))
        (* 5 (hash2-recur (sched-domain-parent a)))))]
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (lambda (obj) 'sched-domain)
      (lambda (obj) (list (sched-domain-groups obj) (sched-domain-parent obj)))))])

(define (make-sched-domain groups [parent #f])
  (define cpu-set (union-group-cpu-sets groups))
  (sched-domain cpu-set groups parent))

;; assume each arch-group becomes a sched-domain, and children are the sched-groups
;; produces a map of cpu to sched domain hierarchy
(define (domain-from-arch arch)
  ;; returns a list of associations
  (define (domain-from-arch-dfs arch parent)
    (cond
      [(arch-cpu? arch) (list (cons arch parent))]
      [(arch-group? arch)
       (define groups
         (for/list ([child (arch-group-children arch)])
           (sched-group (get-cpu-set child))))
       (define domain
         (make-sched-domain groups parent))
       (define children-domains
         (for/list ([child (arch-group-children arch)])
           (domain-from-arch-dfs child domain)))
       (append* children-domains)]))
  (make-immutable-hash (domain-from-arch-dfs arch #f)))

(provide
 (struct-out sched-group)
 (struct-out sched-domain)
 make-sched-group
 make-sched-domain
 domain-from-arch)