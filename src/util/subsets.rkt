#lang racket/base

(require racket/match)

(provide generate-subsets)

(define (generate-subsets lst)
  (define (go lst acc)
    (match lst
      [(list hd tl ...)
       (append (go tl acc)
               (go tl (cons hd acc)))]
      [_ (list acc)]))
  (go lst '()))