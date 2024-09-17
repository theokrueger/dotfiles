;; performance-init.el
;; settings relating to performance of emacs

;; garbage collector settings
(setq-default
  read-process-output-max (* 24 1024 1024) ;; 24mb process reads
  gc-cons-threshold most-positive-fixnum) ;; infinite gc threshold for startup

(add-hook 'emacs-startup-hook
  (lambda () (setq-default gc-cons-threshold (eval-when-compile(* 128 1024 1024))))) ;; 128 mb gc threshold after startup

;; few messages
(setq-default message-log-max 100)
;;(kill-buffer "*Messages*") ;; uncomment and set message-log-max to nil for no messages buffer

;; dont touch this
(provide 'performance-init)
