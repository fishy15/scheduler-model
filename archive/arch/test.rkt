#lang racket

(require
  rackunit
  "../setup/main.rkt"
  "./main.rkt"
  (only-in "../setup/setup-test.rkt" test-with-default))

(test-with-default
 (cpus 10)
 (for ([num '(-1 10 11 'abc)])
   (check-exn exn:fail:contract?
              (lambda () (arch-cpu num))
              (format "constructing cpu ~a should fail" num)))

 (for ([num (in-range 10)])
   (check-not-exn
    (lambda () (arch-cpu num))
    (format "constructing cpu ~a should succeed" num))))

(test-with-default
 (cpus 4)

 (check-equal?
  (arch-group (list (arch-cpu 0) (arch-cpu 1) (arch-cpu 2) (arch-cpu 3)))
  (construct-arch '(0 1 2 3))
  "constructing flat arch type")

 (check-equal?
  (arch-group (list
               (arch-group (list (arch-cpu 0) (arch-cpu 1)))
               (arch-group (list (arch-cpu 2) (arch-cpu 3)))))
  (construct-arch '((0 1) (2 3)))
  "constructing smt-like arch")

 (check-equal?
  (arch-group (list
               (arch-group (list (arch-cpu 0)))
               (arch-group (list (arch-cpu 1)))
               (arch-group (list (arch-cpu 2)))
               (arch-group (list (arch-cpu 3)))))
  (construct-arch '((0) (1) (2) (3)))
  "constructing individual group arch")

 (check-equal?
  (arch-group (list (arch-cpu 0)
                    (arch-group (list (arch-cpu 1)
                                      (arch-group (list (arch-cpu 2)
                                                        (arch-group (list (arch-cpu 3)))))))))
  (construct-arch '(0 (1 (2 (3)))))
  "constructing lopsided arch")

 (define bad-examples
   (list '(0 1 2)
         '(-1 0 1 2 3)
         '(0 1 2 3 4)
         '(1 2 3 4)
         '(abc)))
 (for ([desc bad-examples])
   (check-exn exn:fail:contract?
              (lambda () (construct-arch desc))
              (format "constructing invalid arch ~a should fail" desc))))

(test-with-default
 (cpus 4)

 (check-equal?
  (apply set (map arch-cpu '(0 1 2 3)))
  (get-cpu-set (construct-arch '(0 1 2 3))))

 (check-equal?
  (apply set (map arch-cpu '(0 1 2 3)))
  (get-cpu-set (construct-arch '((0) (1) (2) (3)))))

 (check-equal?
  (apply set (map arch-cpu '(0 1 2 3)))
  (get-cpu-set (construct-arch '((0 1) (2 3)))))

 (check-equal?
  (apply set (map arch-cpu '(0 3)))
  (get-cpu-set (arch-group (list (arch-cpu 0) (arch-cpu 3))))))