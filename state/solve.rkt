#lang rosette/safe

(require json
         "checker.rkt"
         "hidden.rkt"
         "visible.rkt"
         (only-in racket/base with-input-from-file))

(define (solve-case visible topology invariant)
  (let ([hidden (construct-hidden-state-var topology)])
    (define M
      (solve
        (begin
          (assume (valid hidden visible))
          (assert (not (invariant hidden visible))))))
    (if (sat? M)
        (evaluate hidden M)
        #f)))

(define (solve-cases data topology invariant)
  (define (rec data-left)
    (if (null? data-left)
        #f
        (begin
          (define cur-example (read-from-json (car data-left)))
          (define counterexample (solve-case cur-example topology invariant))
          (if counterexample
              counterexample
              (rec (cdr data-left))))))
  (rec data))

(define (solve-from-file file-name topology invariant)
  (with-input-from-file file-name
    (lambda ()
      (solve-cases (read-json) topology invariant))))

(provide solve-cases
         solve-from-file)
