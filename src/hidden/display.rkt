#lang racket/base

(require "cpu.rkt"
         "state.rkt"
         "../util/kw-struct.rkt")

(provide hidden->json-string)

(define (hidden->json-string state)
  (hidden->string-helper state 0))

(define (hidden->string-helper obj level)
  (cond
    [(eq? obj #t) "\"true\",\n"]
    [(eq? obj #f) "\"false\",\n"]
    [(number? obj) (format "~a,\n" obj)]
    [(or (string? obj)
         (symbol? obj)) (format "\"~a\",\n" obj)]
    [(list? obj) (list->json-string obj level hidden->string-helper)]
    [(hidden-state? obj) (hidden-state->json-string obj level hidden->string-helper)]
    [(hidden-cpu? obj) (hidden-cpu->json-string obj level hidden->string-helper)]))