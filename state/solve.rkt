#lang rosette

(require json
	 "checker.rkt"
         "hidden.rkt"
         "visible.rkt")

(define (solve-case visible)
  (let* ([hidden (construct-hidden-state-var)])
    (define M
      (solve
        (begin
          (assume (valid hidden visible))
          (assert (not (correct hidden visible))))))
    (if (sat? M)
        M
        #f)))

(define (solve-cases data)
  (for/or ([visible data])
    (solve-case visible)))

(define (solve-from-file file-name)
  (with-input-from-file file-name
    (lambda ()
      (solve-cases (read-json)))))

(provide solve-cases
         solve-from-file)
