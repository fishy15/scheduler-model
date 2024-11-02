#lang rosette

(require json
         "hidden.rkt"
         "visible.rkt"
         "checker.rkt")

(define (solve-case hidden)
  (let* ([visible (construct-visible-state-var)])
    (define M
      (solve
        (begin
          (assume (valid hidden visible))
          (assert (not (correct hidden visible))))))
    (if (sat? M)
        M
        #f)))

(define (solve-cases data)
  (for/or ([hidden data])
    (solve-case hidden)))

(define (solve-from-file file-name)
  (with-input-from-file file-name
    (lambda ()
      (solve-cases (read-json)))))

(provide solve-cases
         solve-from-file)
