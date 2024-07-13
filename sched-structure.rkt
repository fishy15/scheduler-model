#lang racket

(require racket/struct
         "arch/main.rkt"
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

;; methods on sched group

(define (sched-group-nr-cpus group)
  (set-count (sched-group-cpus group)))

(define (sched-group-nr-running group)
  (for/sum [(cpu (sched-group-cpus group))]
    (cpu-nr-running cpu)))

(define check-list-of-sched-groups
  (check-container-of-type list? "list" sched-group? "sched-group"))

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

(define (make-sched-domain #:parent [parent #f] . groups)
  (define cpu-set (union-group-cpu-sets groups))
  (sched-domain cpu-set groups parent))

;; as mentioned in the documentation, the -> groups pointer must point to the CPU
;; that this structure has been created for
;; the groups inputted into this should be correct except for this
(define (rotate-groups-until-cpu-first base-domain cpu)
  ;; acc stores the reverse of the prefix that we have already processed
  (define (rotate-groups groups [acc '()])
    (match groups
      ['()
       (raise-argument-error 'rotate-groups-until-cpu-first
                             (format "group list is missing cpu ~a" cpu)
                             base-domain)]
      [(list head tail ...)
       (if (set-member? (sched-group-cpus head) cpu)
           (append groups (reverse acc))
           (rotate-groups tail (cons head acc)))]))

  (define (fix-domain domain)
    (if (false? domain)
        #f
        (sched-domain
         (sched-domain-cpu-set domain)
         (rotate-groups (sched-domain-groups domain))
         (fix-domain (sched-domain-parent domain)))))

  (fix-domain base-domain))

(define (rotate-all-groups-until-cpu-first unrotated-groups)
  (for/hash ([key+value (in-hash-pairs unrotated-groups)])
    (match key+value
      [(cons cpu base-domain)
       (values cpu (rotate-groups-until-cpu-first base-domain cpu))])))

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
         (apply make-sched-domain groups #:parent parent))
       (define children-domains
         (for/list ([child (arch-group-children arch)])
           (domain-from-arch-dfs child domain)))
       (append* children-domains)]))
  (define unrotated-groups
    (make-immutable-hash (domain-from-arch-dfs arch #f)))
  (rotate-all-groups-until-cpu-first unrotated-groups))

(provide
 (struct-out sched-group)
 (struct-out sched-domain)
 make-sched-group
 make-sched-domain
 rotate-groups-until-cpu-first
 rotate-all-groups-until-cpu-first
 domain-from-arch)