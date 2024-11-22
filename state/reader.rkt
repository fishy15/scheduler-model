#lang rosette/safe

(require json)

(with-input-from-file "data.json"
  (lambda ()
    (let* ([data (read-json)]
           [entry (list-ref data 0)]
           [cpu (hash-ref entry 'cpu)])
      (displayln cpu))))
