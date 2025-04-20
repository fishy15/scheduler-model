#lang racket/base

(require racket/list
         racket/match
         racket/struct
         syntax/parse/define
         (for-syntax racket/base
                     racket/syntax
                     syntax/parse))

(provide define-kw-struct
         define-struct-with-writer
         n-tabs)

(define (n-tabs n)
  (apply string-append (make-list n "  ")))

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
  #:with writer-name (format-id #'name "~a->string" (syntax-e #'name))
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