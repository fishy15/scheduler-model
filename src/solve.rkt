#lang rosette/safe

(require json
         "checker/main.rkt"
         "hidden/main.rkt"
         "util/subsets.rkt"
         "visible/main.rkt"
         (only-in racket/base with-input-from-file
                  for/fold
                  for/or))

(provide solve-cases
         solve-from-file
         (struct-out success)
         (struct-out inconsistent))

;; possible results from solve-case
(struct success (hidden visible) #:transparent)
(struct inconsistent (visible checks) #:transparent)

(define (check-inconsistency visible [checks all-checks])
  (clear-terms!)
  (let* ([nr-cpus (length (visible-state-per-cpu-info visible))]
         [hidden (construct-hidden-state-var nr-cpus)]
         [hidden-vars (list-symbolic-vars hidden)])
    (define M
      (solve (assume (valid hidden visible checks))))
    (define completed-M (complete-solution M hidden-vars))
    (if (sat? completed-M)
        #f
        (inconsistent visible checks))))

(define (solve-case visible invariant)
  (clear-terms!)
  (let* ([nr-cpus (length (visible-state-per-cpu-info visible))]
         [hidden (construct-hidden-state-var nr-cpus)]
         [hidden-vars (list-symbolic-vars hidden)])
    (define M
      (solve
       (begin
         (assume (valid hidden visible))
         (assert (not (invariant hidden visible))))))
    (define completed-M (complete-solution M hidden-vars))
    (if (sat? completed-M)
        (success (evaluate hidden completed-M) visible)
        #f)))

(define (find-small-inconsistent-set visible)
  (define min-set
    (for/fold ([min-subset #f])
              ([subset (generate-subsets all-checks)]
               #:when (check-inconsistency visible subset))
      (if (or (not min-subset)
              (> (length min-subset) (length subset)))
          subset
          min-subset)))
  (inconsistent visible min-set))

(define (inconsistent-cases blob)
  (for/or ([ex-json blob])
    (let ([ex-data (read-from-json ex-json)])
      (if (check-inconsistency ex-data)
          (find-small-inconsistent-set ex-data)
          #f))))

(define (solve-cases blob invariant)
  (for/or ([ex-json blob])
    (let ([ex-data (read-from-json ex-json)])
      (solve-case ex-data invariant))))

(define (solve-from-file file-name invariants)
  (define (f dd) (check-inconsistency (read-from-json dd)))
  (with-input-from-file file-name
    (lambda ()
      (let ([data (read-json)])
        (or (inconsistent-cases data)
            (map (lambda (inv) (solve-cases data inv)) invariants))))))