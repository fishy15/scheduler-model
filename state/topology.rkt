#lang racket/base

(require racket/set)

(provide (struct-out topology-cpu)
         (struct-out topology-group)
         construct-topology
         check-topology
         get-cpu-set)
         
(struct topology-cpu
  (cpu-id)
  #:transparent)

(struct topology-group
  (children)
  #:transparent)

;; Constructs the topology  from a simpler description
;; that just uses lists and numbers.
;; A list represents a group, and a number represents a CPU.
;; For example, (list (list 0 1) (list 2 3)) represents a two-tiered
;; architecture where CPUs 0 and 1 are in one group and CPUs 2 and 3
;; are in the other group.
(define (construct-topology desc)
  (define (constr-recur desc)
    (cond
      [(integer? desc) (topology-cpu desc)]
      [(list? desc) (topology-group (map constr-recur desc))]
      [else (raise-argument-error 'construct-topology
                                  "type besides int or list present"
                                  desc)]))
  (define topology (constr-recur desc))
  (define nr-cpus (set-count (get-cpu-set topology)))
  (unless (check-topology topology nr-cpus)
    (raise-argument-error 'construct-topology
                          "invalid topology"
                          desc))
  topology)

;; Checks that a constructed topology has a valid tree structure
;; and every CPU is accounted for
(define (check-topology topology nr-cpus)
  ;; gets the list of cpus
  (define (check-topology-recur topology)
    (cond
      [(topology-cpu? topology) (list topology)]
      [(topology-group? topology)
       (for/fold ([acc '()])
                 ([child (topology-group-children topology)]
                  #:break (not acc))
         (let ([child-cpus (check-topology-recur child)])
           (define (member-of-acc v) (member v acc))
           (if (ormap member-of-acc child-cpus)
               #f
               (append acc child-cpus))))]
      [else #f]))
  (define total-cpus (check-topology-recur topology))
  ;; Check that every CPU is present from 0 to nr-cpus - 1
  (if total-cpus
      (and (member (topology-cpu 0) total-cpus)
           (member (topology-cpu (- nr-cpus 1)) total-cpus)
           (equal? (length total-cpus) nr-cpus))
      #f))

;; Returns a set of topology-cpus that are children of the current node
;; in the archicture. The cpu set of a CPU is the singleton set with itself,
;; and the cpu set of a group is the union of its children.
(define (get-cpu-set topology)
  (cond
    [(topology-cpu? topology)
     (set topology)]
    [(topology-group? topology)
     (apply set-union (map get-cpu-set (topology-group-children topology)))]))
