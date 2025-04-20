#lang racket/base

(require "state.rkt"
         "../util/kw-struct.rkt")

(provide visible->string)

(define (visible->string state)
  (visible->string-helper state 0))

(define (visible-list->string lst level)
  (define (conv-item item)
    (string-append (n-tabs (+ level 1))
                   (visible->string-helper item (+ level 1))))
  (define converted-items (map conv-item lst))
  (define args (append (list "[\n")
                       converted-items
                       (list (n-tabs level) "],\n")))
  (apply string-append args))


(define (visible->string-helper obj level)
  (cond
    [(eq? obj #t) "\"true\",\n"]
    [(eq? obj #f) "\"false\",\n"]
    [(number? obj) (format "~a,\n" obj)]
    [(or (string? obj)
         (symbol? obj)) (format "\"~a\",\n" obj)]
    [(list? obj) (visible-list->string obj level)]
    [(visible-state? obj) (visible-state->string obj level visible->string-helper)]
    [(visible-sd-info? obj) (visible-sd-info->string obj level visible->string-helper)]
    [(visible-sd? obj) (visible-sd->string obj level visible->string-helper)]
    [(visible-sg-info? obj) (visible-sg-info->string obj level visible->string-helper)]
    [(visible-cpu-info? obj) (visible-cpu-info->string obj level visible->string-helper)]))