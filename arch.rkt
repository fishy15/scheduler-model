#lang racket

(require racket/struct
         "setup/cpus.rkt")

(struct arch-cpu (num)
  #:guard (lambda (num name)
            (when (equal? #f (cpus))
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
  (if total-cpus
      (and (member (arch-cpu 0) total-cpus)
           (member (arch-cpu (- (cpus) 1)) total-cpus)
           (equal? (length total-cpus) (cpus)))
      #f))

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

(define (get-cpu-set arch)
  (cond
    [(arch-cpu? arch)
     (set arch)]
    [(arch-group? arch)
     (apply set-union (map get-cpu-set (arch-group-children arch)))]))

(provide (all-defined-out))
