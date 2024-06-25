#lang racket

(require
  rackunit
  "setup.rkt"
  "arch.rkt"
  (only-in "setup-test.rkt" test-with-default))

(test-with-default
  (cpus 10)
  (for ([num '(-1 10 11 'abc)])
    (check-exn exn:fail? (lambda () (cpu num))))
  (for ([num (in-range 10)])
    (check-not-exn (lambda () (cpu num)))))

(test-with-default
  (cpus 4)
  (check-equal?
    (group (list (cpu 0) (cpu 1) (cpu 2) (cpu 3)))
    (construct-arch '(0 1 2 3)))
  (check-equal?
    (group (list (group (list (cpu 0) (cpu 1))) (group (list (cpu 2) (cpu 3)))))
    (construct-arch '((0 1) (2 3))))
  (check-equal?
    (group (list 
             (group (list (cpu 0)))
             (group (list (cpu 1)))
             (group (list (cpu 2)))
             (group (list (cpu 3)))))
    (construct-arch '((0) (1) (2) (3))))
  (check-equal?
    (group (list (cpu 0)
                 (group (list (cpu 1)
                              (group (list (cpu 2)
                                           (group (list (cpu 3)))))))))
    (construct-arch '(0 (1 (2 (3))))))
  (define bad-examples
    (list '(0 1 2)
          '(-1 0 1 2 3)
          '(0 1 2 3 4)
          '(1 2 3 4)
          '(abc)))
  (for ([desc bad-examples])
    (check-exn exn:fail? (lambda () (construct-arch desc)))))
