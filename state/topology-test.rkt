#lang racket/base

(require racket/set
         rackunit
         "topology.rkt")

;; Check if CPU is constructed only with integer IDs
;; (test-begin
;;  (cpus 10)
;;  (for ([num '(-1 10 11 'abc)])
;;    (check-exn exn:fail:contract?
;;               (lambda () (arch-cpu num))
;;               (format "constructing cpu ~a should fail" num)))

;;  (for ([num (in-range 10)])
;;    (check-not-exn
;;     (lambda () (arch-cpu num))
;;     (format "constructing cpu ~a should succeed" num))))

(test-begin
  (check-equal?
   (topology-group (list (topology-cpu 0) (topology-cpu 1) (topology-cpu 2) (topology-cpu 3)))
   (construct-topology '(0 1 2 3))
   "constructing flat topology type")

  (check-equal?
   (topology-group (list
                    (topology-group (list (topology-cpu 0) (topology-cpu 1)))
                    (topology-group (list (topology-cpu 2) (topology-cpu 3)))))
   (construct-topology '((0 1) (2 3)))
   "constructing smt-like topology")

  (check-equal?
   (topology-group (list
                    (topology-group (list (topology-cpu 0)))
                    (topology-group (list (topology-cpu 1)))
                    (topology-group (list (topology-cpu 2)))
                    (topology-group (list (topology-cpu 3)))))
   (construct-topology '((0) (1) (2) (3)))
   "constructing individual group topology")

  (check-equal?
   (topology-group (list (topology-cpu 0)
                         (topology-group (list (topology-cpu 1)
                                               (topology-group (list (topology-cpu 2)
                                                                     (topology-group (list (topology-cpu 3)))))))))
   (construct-topology '(0 (1 (2 (3)))))
   "constructing lopsided topology")

  (define bad-examples
    (list '(-1 0 1 2 3)
          '(1 2 3 4)
          '(abc)))
  (for ([desc bad-examples])
    (check-exn exn:fail:contract?
               (lambda () (construct-topology desc))
               (format "constructing invalid topology ~a should fail" desc))))

(test-begin
  (check-equal?
   (apply set (map topology-cpu '(0 1 2 3)))
   (get-cpu-set (construct-topology '(0 1 2 3))))

  (check-equal?
   (apply set (map topology-cpu '(0 1 2 3)))
   (get-cpu-set (construct-topology '((0) (1) (2) (3)))))

  (check-equal?
   (apply set (map topology-cpu '(0 1 2 3)))
   (get-cpu-set (construct-topology '((0 1) (2 3)))))

  (check-equal?
   (apply set (map topology-cpu '(0 3)))
   (get-cpu-set (topology-group (list (topology-cpu 0) (topology-cpu 3))))))
