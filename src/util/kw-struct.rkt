#lang rosette/safe

(require syntax/parse/define
         (only-in racket/base string-append)
         (only-in racket/match match)
         (only-in racket/list make-list)
         (for-syntax racket/base
                     racket/syntax
                     syntax/parse))

(provide define-kw-struct
         define-struct-with-writer
         list->json-string
         n-tabs
         define-struct2)

(define (n-tabs n)
  (apply string-append (make-list n "  ")))

(define (list->json-string lst level writer)
  (define (conv-item item)
    (string-append (n-tabs (+ level 1))
                   (writer item (+ level 1))))
  (define converted-items (map conv-item lst))
  (define args (append (list "[\n")
                       converted-items
                       (list (n-tabs level) "],\n")))
  (apply string-append args))


(define-syntax-parse-rule (define-kw-struct name (field:id ...))
  #:with (field: ...) (map (lambda (fld) (format-symbol "~a:" (syntax-e fld))) (attribute field))
  (struct name (field ...)
    #:transparent
    #:methods gen:custom-write
    [(define write-proc
       (make-constructor-style-printer
        (lambda (obj) 'name)
        (lambda (obj)
          (match obj
            [(name field ...)
             (list {~@ 'field: field} ...)]))))]))

(define-syntax-parse-rule (define-struct-with-writer name (field:id ...))
  #:with (field: ...) (map (lambda (fld) (format-symbol "\"~a\": " (syntax-e fld))) (attribute field))
  #:with writer-name (format-id #'name "~a->json-string" (syntax-e #'name))
  (begin
    (struct name (field ...) #:transparent)
    (define (writer-name obj level writer)
      (match obj
        [(name field ...)
         (string-append
          "{\n"
          {~@ (n-tabs (+ level 1))
              (format "~a" 'field:)
              (writer field (+ level 1))}
          ...
          (n-tabs level)
          "},\n")]))))

(define-syntax-parse-rule (define-struct2 name (field:id ...))
  (begin
    (require (only-in rosette/safe struct))
    (struct name (field ...) #:transparent)))