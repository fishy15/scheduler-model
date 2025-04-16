#lang rosette/safe

(require json
         "checker/main.rkt"
         "hidden/main.rkt"
         "visible/main.rkt"
         (only-in racket/base with-input-from-file
                  for/or))

(provide solve-cases
         solve-from-file
         (struct-out success)
         (struct-out inconsistent))

;; possible results from solve-case
(struct success (visible hidden) #:transparent)
(struct inconsistent (visible) #:transparent)

(define (check-consistency visible)
  (let* ([nr-cpus (length (visible-state-per-cpu-info visible))]
         [hidden (construct-hidden-state-var nr-cpus)]
         [hidden-vars (list-symbolic-vars hidden)])
    (define M
      (solve (assume (valid hidden visible))))
    (define completed-M (complete-solution M hidden-vars))
    (if (sat? completed-M)
        #f
        (inconsistent visible))))

(define (solve-case visible invariant)
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

(define (consistent-cases data)
  (for/or ([ex-json data])
    (let ([data (read-from-json ex-json)])
      (clear-terms!)
      (check-consistency data))))

(define (solve-cases data invariant)
  (for/or ([ex-json data])
    (let ([data (read-from-json ex-json)])
      (clear-terms!)
      (solve-case data invariant))))

(define (solve-from-file file-name invariants)
  (with-input-from-file file-name
    (lambda ()
      (let ([data (read-json)])
        (or (consistent-cases data)
            (map (lambda (inv) (solve-cases data inv)) invariants))))))