#lang racket/base

(require racket/struct
         racket/match
         syntax/parse/define
         (for-syntax racket/base
                     racket/syntax
                     syntax/parse))

(provide define-kw-struct)

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
