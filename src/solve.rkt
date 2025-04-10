#lang rosette/safe

(require json
         "checker/main.rkt"
         "hidden/main.rkt"
         "visible/main.rkt"
         (only-in racket/base with-input-from-file
                  for/or))

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
        (cons (evaluate hidden completed-M) visible)
        ; (evaluate hidden completed-M)
        #f)))

(define (solve-cases data invariant)
  (for/or ([ex-json data])
    (solve-case (read-from-json ex-json) invariant)))

(define (solve-from-file file-name invariant)
  (with-input-from-file file-name
    (lambda ()
      (solve-cases (read-json) invariant))))

(provide solve-cases
         solve-from-file)
