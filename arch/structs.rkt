#lang racket

(require racket/struct
         "../setup/cpus.rkt")

;; Represents a single CPU, represented by its number
(struct arch-cpu (num)
  #:guard (lambda (num name)
            (unless (cpus)
              (raise-argument-error name
                                    "number of cpus has not been set"
                                    num))
            (unless (and (<= 0 num) (< num (cpus)))
              (raise-argument-error name
                                    "cpu number is invalid"
                                    num))
            num)
  #:methods gen:equal+hash
  [(define (equal-proc a b equal?-recur)
     (equal?-recur (arch-cpu-num a) (arch-cpu-num b)))
   (define (hash-proc a hash-recur)
     (hash-recur (arch-cpu-num a)))
   (define (hash2-proc a hash2-recur)
     (hash2-recur (arch-cpu-num a)))]
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (lambda (obj) 'arch-cpu)
      (lambda (obj) (list (arch-cpu-num obj)))))])

;; Represents some grouping of CPUs or groups.
;; For example, both virtual CPUs in SMT situations form a group,
;; and NUMA groups form a group too.
(struct arch-group (children)
  #:guard (lambda (children name)
            (when (null? children)
              (raise-argument-error 'arch-group
                                    "group must not have zero size"
                                    children))
            (for ([child children])
              (unless (or (arch-cpu? child) (arch-group? child))
                (raise-argument-error 'arch-group
                                      "one of the group children is not a group or cpu"
                                      children)))
            children)
  #:methods gen:equal+hash
  [(define (equal-proc a b equal?-recur)
     (equal?-recur (arch-group-children a) (arch-group-children b)))
   (define (hash-proc a hash-recur)
     (hash-recur (arch-group-children a)))
   (define (hash2-proc a hash2-recur)
     (hash2-recur (arch-group-children a)))]
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (lambda (obj) 'arch-group)
      (lambda (obj) (list (arch-group-children obj)))))])

;; Checks that a constructed architecture has a valid tree structure
;; and every CPU is accounted for
(define (check-arch arch)
  ;; gets the list of cpus
  (define (check-arch-recur arch)
    (cond
      [(arch-cpu? arch) (list arch)]
      [(arch-group? arch)
       (for/fold ([acc '()])
                 ([child (arch-group-children arch)]
                  #:break (not acc))
         (let ([child-cpus (check-arch-recur child)])
           (define (member-of-acc v) (member v acc))
           (if (ormap member-of-acc child-cpus)
               #f
               (append acc child-cpus))))]
      [else #f]))
  (define total-cpus (check-arch-recur arch))
  ;; Check that every CPU is present from 0 to (cpus) - 1
  (if total-cpus
      (and (member (arch-cpu 0) total-cpus)
           (member (arch-cpu (- (cpus) 1)) total-cpus)
           (equal? (length total-cpus) (cpus)))
      #f))

;; Constructs the architecture from a simpler description
;; that just uses lists and numbers.
;; A list represents a group, and a number represents a CPU.
;; For example, (list (list 0 1) (list 2 3)) represents a two-tiered
;; architecture where CPUs 0 and 1 are in one group and CPUs 2 and 3
;; are in the other group.
(define (construct-arch desc)
  (define (constr-recur desc)
    (cond
      [(integer? desc) (arch-cpu desc)]
      [(list? desc) (arch-group (map constr-recur desc))]
      [else (raise-argument-error 'construct-arch
                                  "type besides int or list present"
                                  desc)]))
  (define arch (constr-recur desc))
  (unless (check-arch arch)
    (raise-argument-error 'construct-arch
                          "invalid architecture"
                          desc))
  arch)

;; Returns a set of arch-cpus that are children of the current node
;; in the archicture. The cpu set of a CPU is the singleton set with itself,
;; and the cpu set of a group is the union of its children.
(define (get-cpu-set arch)
  (cond
    [(arch-cpu? arch)
     (set arch)]
    [(arch-group? arch)
     (apply set-union (map get-cpu-set (arch-group-children arch)))]))

(provide (struct-out arch-cpu)
         (struct-out arch-group)
         construct-arch
         get-cpu-set)
