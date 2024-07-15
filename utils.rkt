#lang racket

(require racket/generator)

;; Creates a function that checks the type of a container.
;; It first checks the overall type of the container
;; and then the type of every object in it.
;; The function returned has three arguments: the argument we are checking,
;; a description for which argument we are checking in the guard,
;; and the name of the object.
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

;; Returns a sequence of all the unordered pairs in a list.
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