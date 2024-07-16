#lang racket

(struct group-type (type) #:transparent)

(define group-type:has-spare (group-type 'has-spare))
(define group-type:fully-busy (group-type 'fully-busy))
(define group-type:misfit-task (group-type 'misfit-task))
(define group-type:smt-balance (group-type 'smt-balance))
(define group-type:asym-packing (group-type 'asym-packing))
(define group-type:imbalanced (group-type 'imbalanced))
(define group-type:overloaded (group-type 'overloaded))

(define (group-type:has-spare? a) (equal? group-type:has-spare a))
(define (group-type:fully-busy? a) (equal? group-type:fully-busy a))
(define (group-type:misfit-task? a) (equal? group-type:misfit-task a))
(define (group-type:smt-balance? a) (equal? group-type:smt-balance a))
(define (group-type:asym-packing? a) (equal? group-type:asym-packing a))
(define (group-type:imbalanced? a) (equal? group-type:imbalanced a))
(define (group-type:overloaded? a) (equal? group-type:overloaded a))

(provide group-type?
         group-type:has-spare
         group-type:fully-busy
         group-type:misfit-task
         group-type:smt-balance
         group-type:asym-packing
         group-type:imbalanced
         group-type:overloaded
         group-type:has-spare?
         group-type:fully-busy?
         group-type:misfit-task?
         group-type:smt-balance?
         group-type:asym-packing?
         group-type:imbalanced?
         group-type:overloaded?)
