#lang racket

(require racket/generator)

(define (check-container-of-type container? container-name type? type-name)
  (lambda (container arg-desc name)
    (unless (container? container)
      (raise-argument-error name
                            (format "~a must be a ~a" arg-desc container-name)
                            container))
    (for ([elem container])
      (unless (type? elem)
        (raise-argument-error name
                              (format "~a must consist of ~as" arg-desc type-name)
                              container)))))

(define (unordered-pairs lst)
  (in-generator
   (let loop ([x lst])
     (unless (null? x)
       (let ([head (car x)]
             [tail (cdr x)])
         (for ([elem tail])
           (yield (cons head elem)))
         (loop tail))))))

(provide check-container-of-type
         unordered-pairs)