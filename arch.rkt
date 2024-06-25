#lang racket

(require racket/struct
         "setup.rkt")

(struct cpu (num)
  #:guard (lambda (num name)
            (when (equal? #f (cpus))
              (raise-argument-error 'cpu "number of cpus has not been set" num))
            (unless (and (<= 0 num) (< num (cpus)))
              (raise-argument-error 'cpu "cpu number is invalid" num))
            num)
  #:methods gen:equal+hash
  [(define (equal-proc a b equal?-recur)
     (equal?-recur (cpu-num a) (cpu-num b)))
   (define (hash-proc a hash-recur)
      (hash-recur (cpu-num a)))
   (define (hash2-proc a hash2-recur)
      (hash2-recur (cpu-num a)))]
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
       (lambda (obj) 'cpu)
       (lambda (obj) (list (cpu-num obj)))))])

(struct group (children)
  #:guard (lambda (children name)
            (when (null? children)
              (raise-argument-error 'group "group must not have zero size" children))
            (for ([child children])
              (unless (or (cpu? child) (group? child))
                (raise-argument-error 'group "one of the group children is not a group or cpu" children)))
            children)
  #:methods gen:equal+hash
  [(define (equal-proc a b equal?-recur)
     (equal?-recur (group-children a) (group-children b)))
   (define (hash-proc a hash-recur)
      (hash-recur (group-children a)))
   (define (hash2-proc a hash2-recur)
      (hash2-recur (group-children a)))]
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
       (lambda (obj) 'group)
       (lambda (obj) (list (group-children obj)))))])

(define (check-arch arch)
  ;; gets the list of cpus
  (define (check-arch-recur arch)
    (cond
      [(cpu? arch) (list arch)]
      [(group? arch)
        (for/fold ([acc '()])
                  ([child (group-children arch)]
                   #:break (not acc))
          (let ([child-cpus (check-arch-recur child)])
            (define (member-of-acc v) (member v acc))
            (if (ormap member-of-acc child-cpus)
              #f
              (append acc child-cpus))))]
      [else #f]))
  (define total-cpus (check-arch-recur arch))
  (if total-cpus
    (and (member (cpu 0) total-cpus)
         (member (cpu (- (cpus) 1)) total-cpus)
         (equal? (length total-cpus) (cpus)))
    #f))

(define (construct-arch desc)
  (define (constr-recur desc)
    (cond
      [(integer? desc) (cpu desc)]
      [(list? desc) (group (map constr-recur desc))]
      [else (raise-argument-error 'construct-arch "type besides cpu or list present" desc)]))
  (define arch (constr-recur desc))
  (unless (check-arch arch)
    (raise-argument-error 'construct-arch "invalid architecture" desc))
  arch)

(provide (all-defined-out))
