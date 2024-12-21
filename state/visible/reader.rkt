#lang racket/base

(require "state.rkt")

(module+ test
  (require rackunit
           json))

(provide read-from-json)

(define (read-sd sd)
  sd)

(define (read-rq rq)
  rq)

(define (read-mask mask)
  (hash-ref mask 'mask))

;; (define-syntax (define-reader stx)
;;   (syntax-parse stx
;;     (syntax-case stx ()
;;       [(_ (name arg) body)
;;        #`(define (name arg)
;;            (define (access key)
;;              (hash-ref inp key))
;;            (if (null? inp)
;;                #f
;;                body))]))
     

;; (define-syntax-rule (define-reader (type inp) body)
;;   (begin
;;         (define (access key)
;;       (hash-ref inp key))

;;   (define (type inp)
;;     (if (null? inp)
;;         #f
;;         body))))

(define (read-lb-env env)
  (define (access key)
    (hash-ref env key))
  (lb-env
    (read-sd (access 'sd))
    (read-rq (access 'src_rq))
    (access 'src_cpu)
    (access 'dst_cpu)
    (read-rq (access 'dst_rq))
    (read-mask (access 'dst_grpmask))
    (access 'new_dst_cpu)
    (access 'idle)
    (access 'imbalance)
    (read-mask (access 'cpus))
    (access 'flags)
    (access 'loop)
    (access 'loop_break)
    (access 'loop_max)
    (access 'fbq_type)
    (access 'migration_type)))

(define (read-fbq-per-cpu-logmsg pclm)
  (define (access key)
    (hash-ref pclm key))
  (fbq-per-cpu-logmsg
   (access 'cpu_id)
   (access 'rq_type)
   (access 'rq_cfs_h_nr_running)
   (access 'capacity)
   (access 'arch_asym_cpu_priority)
   (access 'migration_type)
   (access 'cpu_load)
   (access 'rq_cpu_capacity)
   (access 'arch_scale_cpu_capacity)
   (access 'sd_imbalance_pct)
   (access 'cpu_util_cfs_boost)
   (access 'rq_misfit_task_load)))

(define (read-fbq-logmsg logmsg)
  (define (access key)
    (hash-ref logmsg key))
  (fbq-logmsg
   (access 'capacity_dst_cpu)
   (access 'sched_smt_active)
   (access 'arch_asym_cpu_priority_dst_cpu)
   (for/list ([pclm (access 'per_cpu_msgs)])
     (read-fbq-per-cpu-logmsg pclm))))

(define (read-fbg-stat stat)
  (define (access key)
    (hash-ref stat key))
  (fbg-stat
   (access 'avg_load)
   (access 'group_load)
   (access 'group_capacity)
   (access 'group_util)
   (access 'group_runnable)
   (access 'sum_nr_running)
   (access 'sum_h_nr_running)
   (access 'idle_cpus)
   (access 'group_weight)
   (access 'group_type)
   (access 'group_asym_packing)
   (access 'group_smt_balance)
   (access 'group_misfit_task_load)))

(define (read-fbg-logmsg logmsg)
  (define (access key)
    (hash-ref logmsg key))
  (fbg-logmsg
   (access 'sd_total_load)
   (access 'sd_total_capacity)
   (access 'sd_avg_load)
   (access 'sd_prefer_sibling)
   (read-fbg-stat (access 'busiest_stat))
   (read-fbg-stat (access 'local_stat))
   (access 'sched_energy_enabled)
   (access 'rd_perf_domain_exists)
   (access 'rd_overutilized)
   (access 'env_imbalance)))

(define (read-swb-per-cpu-logmsg pclm)
  (define (access key)
    (hash-ref pclm key))
  (swb-per-cpu-logmsg
   (access 'cpu_id)
   (access 'idle_cpu)
   (access 'is_core_idle_cpu)))

(define (read-swb-logmsg logmsg)
  (define (access key)
    (hash-ref logmsg key))
  (define (is-null key)
    (null? (access key)))
  (swb-logmsg
   (read-mask (access 'swb_cpus))
   (access 'dst_cpu)
   (read-mask (access 'cpus))
   (access 'idle)
   (access 'dst_nr_running)
   (access 'dst_ttwu_pending)
   (for/list ([pclm (access 'per_cpus_msgs)]) ;; todo fix "cpus"
     (read-swb-per-cpu-logmsg pclm))
   (if (is-null 'group_balance_mask_sg)
       (read-mask (access 'group_balance_mask_sg))
       #f)
   (access 'group_balance_cpu_sg)))
  
(define (read-lb-logmsg logmsg)
  (define (access key)
    (hash-ref logmsg key))
  (if (equal? logmsg 'null)
      #f
      (lb-logmsg
       (read-lb-env (access 'lb_env))
       (read-swb-logmsg (access 'swb_logmsg))
       (read-fbg-logmsg (access 'fbg_logmsg))
       (read-fbq-logmsg (access 'fbq_logmsg)))))
  
(define (read-sd-entry entry)
  (define (access key)
    (hash-ref entry key))
  (sd-entry
    (access 'max_newidle_lb_cost)
    (access 'continue_balancing)
    (access 'interval)
    (access 'need_serialize)
    (read-lb-logmsg (access 'lb_logmsg))
    (access 'new_idle)
    (access 'new_busy)))

(define (read-from-json obj)
  (visible-state
    (hash-ref obj 'cpu)
    (hash-ref obj 'idle)
    (hash-ref obj 'sched_idle_cpu)
    (for/list ([sd-entry (hash-ref obj 'sd_buf)])
      (read-sd-entry sd-entry))))

(module+ test
  (define single-datapoint
    (with-input-from-file "single.json"
      (lambda ()
        (list-ref (read-json) 0))))
  (displayln (read-from-json single-datapoint)))

