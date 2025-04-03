#lang rosette/safe

(require json
         "checker/main.rkt"
         "hidden/main.rkt"
         "visible/main.rkt"
         (only-in racket/base with-input-from-file
                  for/or))

(define (solve-case visible topology invariant)
  (let ([hidden (construct-hidden-state-var topology)])
    (define M
      (solve
       (begin
         (assume (valid hidden visible))
         (assert (not (invariant hidden visible)))
         (displayln "hi")
         (displayln (vc)))))
    (if (sat? M)
        (cons (evaluate hidden M) visible)
        #f)))

(define (solve-cases data topology invariant)
  (for/or ([ex-json data])
    (solve-case (read-from-json ex-json) topology invariant)))

(define (solve-from-file file-name topology invariant)
  (with-input-from-file file-name
    (lambda ()
      (solve-cases (read-json) topology invariant))))

(provide solve-cases
         solve-from-file)
