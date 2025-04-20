#lang racket/base

(require "state.rkt"
         "../util/kw-struct.rkt")

(provide visible->json-string)

(define (visible->json-string state)
  (visible->string-helper state 0))

(define (visible->string-helper obj level)
  (cond
    [(eq? obj #t) "\"true\",\n"]
    [(eq? obj #f) "\"false\",\n"]
    [(number? obj) (format "~a,\n" obj)]
    [(or (string? obj)
         (symbol? obj)) (format "\"~a\",\n" obj)]
    [(list? obj) (list->json-string obj level visible->string-helper)]
    [(visible-state? obj) (visible-state->json-string obj level visible->string-helper)]
    [(visible-sd-info? obj) (visible-sd-info->json-string obj level visible->string-helper)]
    [(visible-sd? obj) (visible-sd->json-string obj level visible->string-helper)]
    [(visible-sg-info? obj) (visible-sg-info->json-string obj level visible->string-helper)]
    [(visible-cpu-info? obj) (visible-cpu-info->json-string obj level visible->string-helper)]))